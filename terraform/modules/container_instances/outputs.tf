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

output "backend_fqdn" {
  description = "The FQDN of the backend container"
  value       = azurerm_container_group.backend.fqdn
}

output "frontend_fqdn" {
  description = "The FQDN of the frontend container"
  value       = azurerm_container_group.frontend.fqdn
}

output "backend_ip_address" {
  description = "The public IP address of the backend container"
  value       = azurerm_container_group.backend.ip_address
}

output "frontend_ip_address" {
  description = "The public IP address of the frontend container"
  value       = azurerm_container_group.frontend.ip_address
}

output "backend_url" {
  description = "The complete URL of the backend API"
  value       = "https://${azurerm_container_group.backend.fqdn}:8000"
}

output "frontend_url" {
  description = "The complete URL of the frontend application"
  value       = "http://${azurerm_container_group.frontend.fqdn}"
}