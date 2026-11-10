# Where this root keeps its own state.
#
# The storage account name is left out on purpose, so it stays out of the
# public repo. Pass it at init time from the gitignored bootstrap.tfbackend:
#   terraform init -backend-config=bootstrap.tfbackend

terraform {
  backend "azurerm" {
    resource_group_name = "rg-northtell-tfstate"
    container_name      = "tfstate"
    key                 = "bootstrap.tfstate"
    use_azuread_auth    = true
  }
}
