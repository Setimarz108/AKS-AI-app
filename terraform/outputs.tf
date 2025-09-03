# terraform/outputs.tf

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Networking outputs
output "vnet_name" {
  description = "The name of the virtual network"
  value       = module.networking.vnet_name
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = module.networking.vnet_id
}

# Container Registry outputs
output "container_registry_name" {
  description = "The name of the container registry"
  value       = module.container_instances.container_registry_name
}

output "container_registry_login_server" {
  description = "The login server for the container registry"
  value       = module.container_instances.container_registry_login_server
}

output "container_registry_admin_username" {
  description = "The admin username for the container registry"
  value       = module.container_instances.container_registry_admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "The admin password for the container registry"
  value       = module.container_instances.container_registry_admin_password
  sensitive   = true
}

# Container Instances outputs
output "backend_url" {
  description = "The complete URL of the backend API"
  value       = module.container_instances.backend_url
}

output "frontend_url" {
  description = "The complete URL of the frontend application"
  value       = module.container_instances.frontend_url
}

output "backend_fqdn" {
  description = "The FQDN of the backend container"
  value       = module.container_instances.backend_fqdn
}

output "frontend_fqdn" {
  description = "The FQDN of the frontend container"
  value       = module.container_instances.frontend_fqdn
}

output "backend_ip_address" {
  description = "The public IP address of the backend container"
  value       = module.container_instances.backend_ip_address
}

output "frontend_ip_address" {
  description = "The public IP address of the frontend container"
  value       = module.container_instances.frontend_ip_address
}

# Key Vault outputs
output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = module.keyvault.key_vault_uri
}

# Optional: Database outputs (uncomment if using database module)
# output "database_server_name" {
#   description = "The name of the PostgreSQL server"
#   value       = module.database.postgresql_server_name
# }

# output "database_connection_string" {
#   description = "The connection string for the database"
#   value       = module.database.connection_string
#   sensitive   = true
# }

# Deployment summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment             = "demo"
    resource_group         = azurerm_resource_group.main.name
    container_registry     = module.container_instances.container_registry_name
    backend_endpoint       = module.container_instances.backend_url
    frontend_endpoint      = module.container_instances.frontend_url
    architecture          = "Azure Container Instances"
  }
}