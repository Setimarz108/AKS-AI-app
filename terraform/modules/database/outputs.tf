# # terraform/modules/database/outputs.tf

# output "postgresql_server_name" {
#   description = "The name of the PostgreSQL server"
#   value       = azurerm_postgresql_flexible_server.main.name
# }

# output "postgresql_server_fqdn" {
#   description = "The FQDN of the PostgreSQL server"
#   value       = azurerm_postgresql_flexible_server.main.fqdn
# }

# # output "database_name" {
# #   description = "The name of the application database"
# #   value       = azurerm_postgresql_flexible_server_database.retailbot.name
# # }

# output "admin_username" {
#   description = "The administrator username"
#   value       = azurerm_postgresql_flexible_server.main.administrator_login
# }

# output "admin_password" {
#   description = "The administrator password"
#   value       = random_password.admin_password.result
#   sensitive   = true
# }

# output "connection_string" {
#   description = "PostgreSQL connection string for applications"
#   value       = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:${random_password.admin_password.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.retailbot.name}?sslmode=require"
#   sensitive   = true
# }

# output "connection_info" {
#   description = "Database connection details for application configuration"
#   value = {
#     host     = azurerm_postgresql_flexible_server.main.fqdn
#     port     = 5432
#     database = azurerm_postgresql_flexible_server_database.retailbot.name
#     username = azurerm_postgresql_flexible_server.main.administrator_login
#     password = random_password.admin_password.result
#     sslmode  = "require"
#   }
#   sensitive = true
# }

# output "server_id" {
#   description = "The ID of the PostgreSQL server"
#   value       = azurerm_postgresql_flexible_server.main.id
# }

# output "server_fqdn" {
#   description = "PostgreSQL server FQDN"
#   value       = azurerm_postgresql_flexible_server.main.fqdn
# }