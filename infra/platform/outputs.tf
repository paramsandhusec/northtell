# Values other roots and checks need from the platform root.

output "automation_account_name" {
  description = "Name of the automation account that runs Stop-LabVMs."
  value       = azurerm_automation_account.kill_switch.name
}
