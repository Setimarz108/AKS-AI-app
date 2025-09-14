# terraform/outputs.tf

# Replace the old outputs with these:
output "app_fqdn" {
  description = "The FQDN of the application"
  value       = module.container_instances.app_fqdn
}

output "app_ip_address" {
  description = "The IP address of the application"
  value       = module.container_instances.app_ip_address
}

output "frontend_url" {
  description = "The complete URL of the frontend application"
  value       = module.container_instances.frontend_url
}

output "backend_url" {
  description = "The complete URL of the backend API"
  value       = module.container_instances.backend_url
}

# output "database_server_fqdn" {
#   description = "Database server FQDN"
#   value       = module.database.server_fqdn 
#   sensitive   = true
# }

# output "database_name" {
#   description = "Database name"
#   value       = module.database.database_name
# }

