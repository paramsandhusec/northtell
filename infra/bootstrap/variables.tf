# Inputs for the bootstrap root.

variable "location" {
  description = "Azure region for the state storage."
  type        = string
  default     = "canadacentral"
}

variable "storage_account_name" {
  description = "Globally unique name for the state storage account. Set in bootstrap.auto.tfvars, which is gitignored."
  type        = string
}
