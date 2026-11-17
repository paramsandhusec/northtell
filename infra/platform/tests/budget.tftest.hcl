# Unit test for the budget and the scheduled kill switch. It runs an apply
# against a mock provider, so it needs no Azure login and creates nothing.
# Apply, not plan, so resource IDs are known and asserts can compare one with
# another.

mock_provider "azurerm" {
  # The mock makes up random strings for IDs, but the provider checks that
  # IDs have the right Azure shape. Give the ones it checks a real shape.
  mock_data "azurerm_subscription" {
    defaults = {
      id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "azurerm_automation_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-northtell-platform/providers/Microsoft.Automation/automationAccounts/aa-northtell-killswitch"
      identity = {
        principal_id = "11111111-1111-1111-1111-111111111111"
        tenant_id    = "22222222-2222-2222-2222-222222222222"
      }
    }
  }
}

variables {
  alert_email = "alerts@example.com"
}

run "budget_and_kill_switch" {
  command = apply

  # Budget: the existing guardrail-manual budget, alerts by email only.

  assert {
    condition     = azurerm_consumption_budget_subscription.monthly.name == "guardrail-manual"
    error_message = "Terraform must manage the existing guardrail-manual budget, not create a second one."
  }

  assert {
    condition     = azurerm_consumption_budget_subscription.monthly.amount == 100
    error_message = "The monthly budget must be 100 CAD."
  }

  assert {
    condition = (
      azurerm_consumption_budget_subscription.monthly.time_period[0].start_date == "2026-10-01T00:00:00Z" &&
      azurerm_consumption_budget_subscription.monthly.time_period[0].end_date == "2028-09-30T00:00:00Z"
    )
    error_message = "Budget dates must match the live guardrail-manual budget, or the import plan changes or replaces it."
  }

  assert {
    condition = toset([
      for n in azurerm_consumption_budget_subscription.monthly.notification :
      "${n.threshold} ${n.threshold_type}"
      ]) == toset([
      "50 Actual", "80 Actual", "90 Actual", "100 Actual", "100 Forecasted",
    ])
    error_message = "Budget alerts must be 50, 80, 90 and 100 percent actual, plus 100 percent forecasted."
  }

  assert {
    condition = alltrue([
      for n in azurerm_consumption_budget_subscription.monthly.notification :
      try(length(n.contact_groups), 0) == 0
    ])
    error_message = "Budget alerts only send email. The scheduled job is the kill switch, so no alert may call an action group."
  }

  # Automation account: nothing outside Azure needs to call it.

  assert {
    condition     = azurerm_automation_account.kill_switch.identity[0].type == "SystemAssigned"
    error_message = "The automation account must log in with its own system-assigned identity."
  }

  assert {
    condition     = azurerm_automation_account.kill_switch.public_network_access_enabled == false
    error_message = "Public network access must be off. A schedule starts the runbook from inside Azure."
  }

  assert {
    condition     = azurerm_automation_account.kill_switch.local_authentication_enabled == false
    error_message = "Local auth must be off. With no webhook, nothing needs it."
  }

  assert {
    condition = (
      azurerm_automation_runbook.stop_lab_vms.runbook_type == "PowerShell" &&
      azurerm_automation_runbook.stop_lab_vms.runtime_environment_name == "PowerShell-7.2"
    )
    error_message = "The runbook must run on PowerShell 7.2, set through a runtime environment. The older PowerShell72 type reads back as PowerShell and forces a replacement on every plan."
  }

  # Schedule: every 4 hours, linked to the runbook, with the right inputs.

  assert {
    condition     = azurerm_automation_schedule.cost_check.frequency == "Hour" && azurerm_automation_schedule.cost_check.interval == 4
    error_message = "The kill switch must check cost every 4 hours."
  }

  assert {
    condition = (
      azurerm_automation_job_schedule.kill_switch.schedule_name == azurerm_automation_schedule.cost_check.name &&
      azurerm_automation_job_schedule.kill_switch.runbook_name == azurerm_automation_runbook.stop_lab_vms.name
    )
    error_message = "The cost-check schedule must start the Stop-LabVMs runbook."
  }

  assert {
    condition = azurerm_automation_job_schedule.kill_switch.parameters == tomap({
      subscriptionids = "00000000-0000-0000-0000-000000000000"
      thresholdcad    = "90"
    })
    error_message = "With no lab subscriptions set, the job must check this subscription only, against 90 CAD."
  }

  # Roles: stop VMs and read cost in each subscription, and nothing more.

  assert {
    condition = toset([
      for r in values(azurerm_role_assignment.kill_switch_vm_contributor) :
      "${r.role_definition_name} ${r.scope} ${r.principal_id}"
      ]) == toset([
      "Virtual Machine Contributor /subscriptions/00000000-0000-0000-0000-000000000000 11111111-1111-1111-1111-111111111111",
    ])
    error_message = "The automation identity must get Virtual Machine Contributor on each checked subscription."
  }

  assert {
    condition = toset([
      for r in values(azurerm_role_assignment.kill_switch_cost_reader) :
      "${r.role_definition_name} ${r.scope} ${r.principal_id}"
      ]) == toset([
      "Cost Management Reader /subscriptions/00000000-0000-0000-0000-000000000000 11111111-1111-1111-1111-111111111111",
    ])
    error_message = "The automation identity must get Cost Management Reader on each checked subscription."
  }
}

run "second_subscription" {
  command = apply

  variables {
    lab_subscription_ids = ["33333333-3333-3333-3333-333333333333"]
  }

  assert {
    condition     = azurerm_automation_job_schedule.kill_switch.parameters["subscriptionids"] == "00000000-0000-0000-0000-000000000000,33333333-3333-3333-3333-333333333333"
    error_message = "The job must add up this subscription and every lab subscription."
  }

  assert {
    condition = toset([for r in values(azurerm_role_assignment.kill_switch_vm_contributor) : r.scope]) == toset([
      "/subscriptions/00000000-0000-0000-0000-000000000000",
      "/subscriptions/33333333-3333-3333-3333-333333333333",
    ])
    error_message = "Virtual Machine Contributor must cover every checked subscription."
  }

  assert {
    condition = toset([for r in values(azurerm_role_assignment.kill_switch_cost_reader) : r.scope]) == toset([
      "/subscriptions/00000000-0000-0000-0000-000000000000",
      "/subscriptions/33333333-3333-3333-3333-333333333333",
    ])
    error_message = "Cost Management Reader must cover every checked subscription."
  }
}
