# Kill switch. Runs on a schedule, adds up this month's cost across the
# given subscriptions, and stops every lab VM once the total reaches the
# threshold.
param(
    # Comma-separated, because job schedule parameters can only be strings.
    [Parameter(Mandatory)]
    [string]$SubscriptionIds,

    [Parameter(Mandatory)]
    [double]$ThresholdCad
)

$ErrorActionPreference = 'Stop'

$query = @{
    type      = 'ActualCost'
    timeframe = 'MonthToDate'
    dataset   = @{
        granularity = 'None'
        aggregation = @{ totalCost = @{ name = 'Cost'; function = 'Sum' } }
    }
} | ConvertTo-Json -Depth 5

Connect-AzAccount -Identity | Out-Null

$subscriptions = @($SubscriptionIds -split ',' | ForEach-Object Trim | Where-Object { $_ })
$total = 0

foreach ($sub in $subscriptions) {
    # Cost Management throttles often (HTTP 429). Wait and try again, up to
    # 3 attempts; any other error fails at once.
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        $response = Invoke-AzRestMethod -Method POST `
            -Path "/subscriptions/$sub/providers/Microsoft.CostManagement/query?api-version=2023-03-01" `
            -Payload $query

        if ($response.StatusCode -ne 429 -or $attempt -eq 3) { break }
        Start-Sleep -Seconds 60
    }

    if ($response.StatusCode -ne 200) {
        throw "Cost query for subscription $sub failed with HTTP $($response.StatusCode)"
    }

    $result = ($response.Content | ConvertFrom-Json).properties
    $names = @($result.columns.name)
    $costColumn = $names.IndexOf('Cost')
    $currencyColumn = $names.IndexOf('Currency')

    foreach ($row in $result.rows) {
        if ($row[$currencyColumn] -ne 'CAD') {
            throw "Subscription $sub reports cost in $($row[$currencyColumn]), not CAD; the total would be wrong"
        }
        $total += [double]$row[$costColumn]
    }
}

$summary = "Month-to-date $([math]::Round($total, 2)) CAD, threshold $ThresholdCad CAD"

if ($total -lt $ThresholdCad) {
    "${summary}: under, no VMs stopped"
    return
}

"${summary}: over, stopping VMs"

$stopped = 0
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub | Out-Null

    foreach ($vm in @(Get-AzVM -Status | Where-Object PowerState -ne 'VM deallocated')) {
        Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -NoWait | Out-Null
        $stopped++
    }
}

"Stopped $stopped VMs"
