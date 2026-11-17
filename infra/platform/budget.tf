# Monthly budget for the subscription, with email alerts. The budget never
# stops anything; the scheduled job in kill_switch.tf does that.
#
# guardrail-manual was made by hand in the portal before this root existed.
# Adopt it once with terraform import before the first plan, so Terraform
# does not create a second budget that sends every alert twice:
#   terraform import azurerm_consumption_budget_subscription.monthly \
#     "/subscriptions/<subscription-id>/providers/Microsoft.Consumption/budgets/guardrail-manual"
# An import block is not used because terraform test cannot import into a
# mock provider.

data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "guardrail-manual"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.monthly_budget_cad
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  notification {
    threshold      = 50
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    threshold      = 80
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    threshold      = 90
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    threshold      = 100
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    threshold      = 100
    threshold_type = "Forecasted"
    operator       = "GreaterThan"
    contact_emails = [var.alert_email]
  }
}
