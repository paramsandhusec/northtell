# Where this root keeps its state: the same storage as bootstrap, its own file.
#
# The storage account name is left out on purpose, so it stays out of the
# public repo. Pass it at init time from the gitignored platform.tfbackend:
#   terraform init -backend-config=platform.tfbackend

terraform {
  backend "azurerm" {
    resource_group_name = "rg-northtell-tfstate"
    container_name      = "tfstate"
    key                 = "platform.tfstate"
    use_azuread_auth    = true
  }
}
