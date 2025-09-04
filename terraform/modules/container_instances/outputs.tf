# terraform/modules/container_instances/outputs.tf

output "container_registry_name" {
  description = "The name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "The login server for the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "The admin username for the container registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "The admin password for the container registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "app_fqdn" {
  description = "The FQDN of the unified application container group"
  value       = azurerm_container_group.app.fqdn
}

output "app_ip_address" {
  description = "The public IP address of the application"
  value       = azurerm_container_group.app.ip_address
}

output "frontend_url" {
  description = "The URL to access the frontend application"
  value       = "http://${azurerm_container_group.app.fqdn}"
}

output "backend_url" {
  description = "The URL to access the backend API"
  value       = "http://${azurerm_container_group.app.fqdn}:8000"
}