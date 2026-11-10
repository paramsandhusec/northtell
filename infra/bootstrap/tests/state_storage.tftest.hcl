# Unit test for the Terraform state storage. It runs a plan against a mock
# provider, so it needs no Azure login and creates nothing.

mock_provider "azurerm" {}

variables {
  storage_account_name = "sttestnorthtell01"
}

run "storage_is_hardened" {
  command = plan

  assert {
    condition     = azurerm_storage_account.state.shared_access_key_enabled == false
    error_message = "Shared access keys must be off, so access needs an Entra ID identity."
  }

  assert {
    condition     = azurerm_storage_account.state.local_user_enabled == false
    error_message = "Local users must be off, so no SFTP or NFS login bypasses Entra ID."
  }

  assert {
    condition     = azurerm_storage_account.state.min_tls_version == "TLS1_2"
    error_message = "The storage account must refuse TLS older than 1.2."
  }

  assert {
    condition     = azurerm_storage_account.state.allow_nested_items_to_be_public == false
    error_message = "No container or blob in the account may be made public."
  }

  assert {
    condition     = azurerm_storage_account.state.blob_properties[0].versioning_enabled == true
    error_message = "Blob versioning must be on, so an overwritten state file can be restored."
  }

  assert {
    condition     = azurerm_storage_account.state.blob_properties[0].delete_retention_policy[0].days == 30
    error_message = "Deleted blobs must be kept for 30 days."
  }

  assert {
    condition     = azurerm_storage_account.state.blob_properties[0].container_delete_retention_policy[0].days == 30
    error_message = "Deleted containers must be kept for 30 days."
  }

  assert {
    condition     = azurerm_storage_container.tfstate.container_access_type == "private"
    error_message = "The tfstate container must be private."
  }

  assert {
    condition     = azurerm_storage_account.state.location == "canadacentral"
    error_message = "State must live in canadacentral."
  }
}
