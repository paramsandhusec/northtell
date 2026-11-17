# The kill switch: every 4 hours a schedule starts a runbook that adds up
# this month's cost across all checked subscriptions and, once the total
# reaches the threshold, stops every lab VM. Nothing outside Azure calls it,
# so the automation account takes no public traffic and has no webhook.

locals {
  # This subscription first, then any lab subscriptions, with no repeats.
  kill_switch_subscriptions = distinct(concat(
    [data.azurerm_subscription.current.subscription_id],
    var.lab_subscription_ids,
  ))
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-northtell-platform"
  location = var.location
}

resource "azurerm_automation_account" "kill_switch" {
  name                          = "aa-northtell-killswitch"
  location                      = azurerm_resource_group.platform.location
  resource_group_name           = azurerm_resource_group.platform.name
  sku_name                      = "Basic"
  public_network_access_enabled = false
  local_authentication_enabled  = false

  # The runbook logs in as this identity. Azure creates and deletes it with
  # the account, and there is no secret to store.
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_automation_runbook" "stop_lab_vms" {
  name                    = "Stop-LabVMs"
  location                = azurerm_resource_group.platform.location
  resource_group_name     = azurerm_resource_group.platform.name
  automation_account_name = azurerm_automation_account.kill_switch.name
  log_progress            = false
  log_verbose             = false

  # PowerShell 7.2 through the account's built-in runtime environment. The
  # older runbook_type "PowerShell72" reads back as "PowerShell" and would
  # force a replacement on every plan.
  runbook_type             = "PowerShell"
  runtime_environment_name = "PowerShell-7.2"

  # The same script the Pester tests run.
  content = file("${path.module}/runbooks/Stop-LabVMs.ps1")
}

# No start_time: Azure starts the schedule a few minutes after it is created
# and Terraform keeps that value, so later plans show no change.
resource "azurerm_automation_schedule" "cost_check" {
  name                    = "every-4-hours"
  resource_group_name     = azurerm_resource_group.platform.name
  automation_account_name = azurerm_automation_account.kill_switch.name
  frequency               = "Hour"
  interval                = 4
  description             = "Checks month-to-date cost and stops the lab when it reaches the threshold."
}

resource "azurerm_automation_job_schedule" "kill_switch" {
  resource_group_name     = azurerm_resource_group.platform.name
  automation_account_name = azurerm_automation_account.kill_switch.name
  schedule_name           = azurerm_automation_schedule.cost_check.name
  runbook_name            = azurerm_automation_runbook.stop_lab_vms.name

  # Azure stores parameter names in lowercase; PowerShell matches them
  # to the runbook's parameters without caring about case.
  parameters = {
    subscriptionids = join(",", local.kill_switch_subscriptions)
    thresholdcad    = tostring(var.kill_switch_threshold_cad)
  }

  # The first run should already have its roles.
  depends_on = [
    azurerm_role_assignment.kill_switch_vm_contributor,
    azurerm_role_assignment.kill_switch_cost_reader,
  ]

  # Replacing the runbook deletes this link in Azure. Recreate the link
  # whenever the runbook is replaced, so the schedule never stops starting it.
  lifecycle {
    replace_triggered_by = [azurerm_automation_runbook.stop_lab_vms.id]
  }
}

# Enough to stop VMs in each checked subscription, and nothing more.
resource "azurerm_role_assignment" "kill_switch_vm_contributor" {
  for_each = toset(local.kill_switch_subscriptions)

  scope                = "/subscriptions/${each.value}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.kill_switch.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Read-only access to each checked subscription's cost.
resource "azurerm_role_assignment" "kill_switch_cost_reader" {
  for_each = toset(local.kill_switch_subscriptions)

  scope                = "/subscriptions/${each.value}"
  role_definition_name = "Cost Management Reader"
  principal_id         = azurerm_automation_account.kill_switch.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
