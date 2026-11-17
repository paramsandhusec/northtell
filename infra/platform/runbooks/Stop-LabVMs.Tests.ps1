BeforeAll {
    $script:Runbook = Join-Path $PSScriptRoot 'Stop-LabVMs.ps1'
    $script:SubA = 'aaaaaaaa-0000-0000-0000-000000000000'
    $script:SubB = 'bbbbbbbb-0000-0000-0000-000000000000'

    # Stand-ins for the Az cmdlets so the tests run without the Az modules
    # or an Azure login. Each test replaces them with a Mock.
    function Connect-AzAccount { param([switch]$Identity) }
    function Set-AzContext { param($SubscriptionId) }
    function Invoke-AzRestMethod { param($Method, $Path, $Payload) }
    function Get-AzVM { param([switch]$Status) }
    function Stop-AzVM { param($ResourceGroupName, $Name, [switch]$Force, [switch]$NoWait) }

    # The shape Cost Management returns: column names, then one row per group.
    function New-CostResponse ($Cost, $Currency = 'CAD') {
        [pscustomobject]@{
            StatusCode = 200
            Content    = @{
                properties = @{
                    columns = @(
                        @{ name = 'Cost'; type = 'Number' }
                        @{ name = 'Currency'; type = 'String' }
                    )
                    rows    = @(, @($Cost, $Currency))
                }
            } | ConvertTo-Json -Depth 5
        }
    }

    function New-TestVM ($Name, $PowerState) {
        [pscustomobject]@{
            Name              = $Name
            ResourceGroupName = 'rg-northtell-lab'
            PowerState        = $PowerState
        }
    }

    function Invoke-Runbook {
        & $script:Runbook -SubscriptionIds "$script:SubA,$script:SubB" -ThresholdCad 90
    }
}

Describe 'Stop-LabVMs' {
    BeforeEach {
        Mock Connect-AzAccount {}
        Mock Set-AzContext {}
        Mock Stop-AzVM {}
        Mock Start-Sleep {}
        Mock Get-AzVM {
            New-TestVM 'vm-dc01' 'VM running'
            New-TestVM 'vm-win01' 'VM deallocated'
        }
    }

    It 'stops nothing while the total is under the threshold' {
        Mock Invoke-AzRestMethod { New-CostResponse 40 }

        $output = Invoke-Runbook

        Should -Invoke Stop-AzVM -Times 0 -Exactly
        $output | Should -Contain 'Month-to-date 80 CAD, threshold 90 CAD: under, no VMs stopped'
    }

    It 'counts a subscription with no cost rows yet, early in the month, as zero' {
        Mock Invoke-AzRestMethod {
            [pscustomobject]@{
                StatusCode = 200
                Content    = '{"properties":{"columns":[{"name":"Cost","type":"Number"},{"name":"Currency","type":"String"}],"rows":[]}}'
            }
        }

        $output = Invoke-Runbook

        $output | Should -Contain 'Month-to-date 0 CAD, threshold 90 CAD: under, no VMs stopped'
        Should -Invoke Stop-AzVM -Times 0 -Exactly
    }

    It 'adds up every subscription, so two costs under the threshold can trip it together' {
        # Literal prefixes: a mock's ParameterFilter cannot see $script: variables.
        Mock Invoke-AzRestMethod { New-CostResponse 50 } -ParameterFilter { $Path -like '*/aaaaaaaa-*' }
        Mock Invoke-AzRestMethod { New-CostResponse 45 } -ParameterFilter { $Path -like '*/bbbbbbbb-*' }

        $output = Invoke-Runbook

        $output | Should -Contain 'Month-to-date 95 CAD, threshold 90 CAD: over, stopping VMs'
        Should -Invoke Stop-AzVM -Times 2 -Exactly
    }

    It 'stops running VMs in each subscription and skips deallocated ones' {
        Mock Invoke-AzRestMethod { New-CostResponse 90 }

        $output = Invoke-Runbook

        Should -Invoke Set-AzContext -Times 1 -Exactly -ParameterFilter { $SubscriptionId -eq $script:SubA }
        Should -Invoke Set-AzContext -Times 1 -Exactly -ParameterFilter { $SubscriptionId -eq $script:SubB }
        Should -Invoke Stop-AzVM -Times 2 -Exactly -ParameterFilter { $Name -eq 'vm-dc01' -and $Force -and $NoWait }
        $output | Should -Contain 'Stopped 2 VMs'
    }

    It 'fails when a subscription reports a currency other than CAD' {
        Mock Invoke-AzRestMethod { New-CostResponse 10 'USD' }

        { Invoke-Runbook } | Should -Throw '*USD*'
        Should -Invoke Stop-AzVM -Times 0 -Exactly
    }

    It 'fails at once when the cost query fails with an error other than throttling' {
        Mock Invoke-AzRestMethod { [pscustomobject]@{ StatusCode = 500; Content = '{}' } }

        { Invoke-Runbook } | Should -Throw '*500*'
        Should -Invoke Invoke-AzRestMethod -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
        Should -Invoke Stop-AzVM -Times 0 -Exactly
    }

    It 'waits 60 seconds and retries when Cost Management throttles a query' {
        $script:calls = 0
        Mock Invoke-AzRestMethod {
            $script:calls++
            if ($script:calls -eq 1) { [pscustomobject]@{ StatusCode = 429; Content = '{}' } }
            else { New-CostResponse 50 }
        }

        $output = Invoke-Runbook

        $output | Should -Contain 'Month-to-date 100 CAD, threshold 90 CAD: over, stopping VMs'
        Should -Invoke Invoke-AzRestMethod -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 60 }
    }

    It 'gives up after 3 throttled attempts' {
        Mock Invoke-AzRestMethod { [pscustomobject]@{ StatusCode = 429; Content = '{}' } }

        { Invoke-Runbook } | Should -Throw '*429*'
        Should -Invoke Invoke-AzRestMethod -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 2 -Exactly
        Should -Invoke Stop-AzVM -Times 0 -Exactly
    }
}
