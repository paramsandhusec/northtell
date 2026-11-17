# Terraform and provider versions for the platform root.
# Same version constraint as infra/bootstrap. Each root has its own lock file,
# so the exact provider version can differ until Dependabot updates both.

terraform {
  required_version = ">= 1.17.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.13"
    }
  }
}
