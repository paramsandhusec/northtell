# Values the platform and lab roots need for their azurerm backend blocks.

output "state_resource_group" {
  description = "Resource group that holds the state storage."
  value       = azurerm_resource_group.state.name
}

output "state_storage_account" {
  description = "Storage account that holds every root's state."
  value       = azurerm_storage_account.state.name
}

output "state_container" {
  description = "Blob container for the state files."
  value       = azurerm_storage_container.tfstate.name
}
