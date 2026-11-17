# Inputs for the platform root.

variable "location" {
  description = "Azure region for the platform resources."
  type        = string
  default     = "canadacentral"
}

variable "monthly_budget_cad" {
  description = "Monthly spending limit for the subscription, in CAD. Alerts fire at 50, 80, 90 and 100 percent of it."
  type        = number
  default     = 100
}

variable "alert_email" {
  description = "Address that receives budget emails. Set in platform.auto.tfvars, which is gitignored."
  type        = string
  sensitive   = true
}

variable "budget_start_date" {
  description = "First day the budget counts from. Must match the start date of the existing guardrail-manual budget."
  type        = string
  default     = "2026-10-01T00:00:00Z"
}

variable "budget_end_date" {
  description = "Last day the budget counts. Must match the end date of the existing guardrail-manual budget."
  type        = string
  default     = "2028-09-30T00:00:00Z"
}

variable "kill_switch_threshold_cad" {
  description = "Month-to-date cost, summed across all checked subscriptions, at which the kill switch stops every lab VM."
  type        = number
  default     = 90

  validation {
    condition     = var.kill_switch_threshold_cad > 0
    error_message = "The kill-switch threshold must be more than 0 CAD."
  }
}

variable "lab_subscription_ids" {
  description = "Extra subscriptions the kill switch checks and stops, besides this one. Set in platform.auto.tfvars, which is gitignored."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for id in var.lab_subscription_ids :
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))
    ])
    error_message = "Each lab subscription ID must be a bare lowercase GUID, not a /subscriptions/ path."
  }
}
