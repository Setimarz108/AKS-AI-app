# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "~>3.80"
#     }
#     random = {
#       source  = "hashicorp/random"
#       version = "~>3.1"
#     }
#   }
# }

# resource "random_string" "suffix" {
#   length  = 4
#   special = false
#   upper   = false
# }

# resource "random_password" "admin_password" {
#   length  = 16
#   special = true
#   upper   = true
#   lower   = true
#   numeric = true
# }

# # PostgreSQL Flexible Server with PUBLIC access
# resource "azurerm_postgresql_flexible_server" "main" {
#   name                = "psql-${var.project_name}-${var.environment}-${random_string.suffix.result}"
#   resource_group_name = var.resource_group_name
#   location            = var.location

#   # Cost-effective configuration for demo
#   sku_name   = "B_Standard_B1ms"
#   storage_mb = 32768
#   version    = "15"

#   # Enable PUBLIC access (changed from false)
#   public_network_access_enabled = true

#   # Authentication
#   administrator_login    = var.admin_username
#   administrator_password = random_password.admin_password.result

#   # Backup configuration
#   backup_retention_days        = 7
#   geo_redundant_backup_enabled = false

#   # Maintenance window
#   maintenance_window {
#     day_of_week  = 0
#     start_hour   = 2
#     start_minute = 0
#   }

#   tags = var.tags
  
#   # Remove the depends_on that references non-existent variable
# }

# # Firewall rule to allow Azure services
# resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
#   name             = "AllowAzureServices"
#   server_id        = azurerm_postgresql_flexible_server.main.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "0.0.0.0"
# }

# # Database for the application
# resource "azurerm_postgresql_flexible_server_database" "retailbot" {
#   name      = var.database_name
#   server_id = azurerm_postgresql_flexible_server.main.id
#   collation = "en_US.utf8"
#   charset   = "utf8"
# }

# # Rest of your configuration blocks remain the same...
# resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
#   name      = "log_statement"
#   server_id = azurerm_postgresql_flexible_server.main.id
#   value     = "mod"
# }

# resource "azurerm_postgresql_flexible_server_configuration" "log_min_duration_statement" {
#   name      = "log_min_duration_statement"
#   server_id = azurerm_postgresql_flexible_server.main.id
#   value     = "1000"
# }

# resource "azurerm_postgresql_flexible_server_configuration" "shared_preload_libraries" {
#   name      = "shared_preload_libraries"
#   server_id = azurerm_postgresql_flexible_server.main.id
#   value     = "pg_stat_statements"
# }