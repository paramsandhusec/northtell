# Remote state storage for every Northtell Terraform root.

provider "azurerm" {
  features {}

  # Reach blob storage with Entra ID, because shared keys are off.
  storage_use_azuread = true
}

# Who is running Terraform: used to grant the maintainer access to the state.
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "state" {
  name     = "rg-northtell-tfstate"
  location = var.location
}

resource "azurerm_storage_account" "state" {
  #checkov:skip=CKV_AZURE_59: GitHub-hosted runners have no fixed IPs, so the endpoint stays public; access needs Entra ID because shared keys are off.
  #checkov:skip=CKV2_AZURE_33: A private endpoint needs runners inside a VNet; same reason as CKV_AZURE_59.
  #checkov:skip=CKV_AZURE_206: LRS is enough for a lab; blob versioning and 30-day soft delete cover state loss.
  #checkov:skip=CKV2_AZURE_1: Microsoft-managed keys; a customer-managed key adds a Key Vault for no gain in a lab.
  #checkov:skip=CKV_AZURE_33: The account uses no queues.
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  local_user_enabled              = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  #checkov:skip=CKV2_AZURE_21: Blob read logging needs a Log Analytics workspace, which arrives with the lab.
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "maintainer_blob_access" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
