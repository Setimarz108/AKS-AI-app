output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "container_registry_name" {
  description = "Container Registry name"
  value       = module.aks.container_registry_name
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = module.aks.container_registry_login_server
}

output "database_server_name" {
  description = "PostgreSQL server name"
  value       = module.database.postgresql_server_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.aks.key_vault_uri
}

# Sensitive outputs for CI/CD (use with terraform output -raw)
output "container_registry_admin_username" {
  description = "Container Registry admin username"
  value       = module.aks.container_registry_admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Container Registry admin password"
  value       = module.aks.container_registry_admin_password
  sensitive   = true
}

output "kube_config" {
  description = "Kubernetes config for kubectl"
  value       = module.aks.kube_config
  sensitive   = true
}