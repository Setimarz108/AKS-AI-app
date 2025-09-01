# Generate random password for database
resource "random_password" "postgresql_admin_password" {
  length  = 16
  special = true
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# PostgreSQL Flexible Server - PRIVATE ACCESS ONLY
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "14"
  
  # PRIVATE NETWORK CONFIGURATION - This automatically disables public access
  delegated_subnet_id = var.database_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

   # Explicitly disable public network access
  public_network_access_enabled = false
  
  # Authentication
  administrator_login    = var.admin_username
  administrator_password = random_password.postgresql_admin_password.result
  
  # Instance configuration

  storage_mb = var.storage_mb
  sku_name   = var.sku_name
  
  # Backup configuration
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = false  # Keep it simple for demo

  tags = var.tags
}

# Database
resource "azurerm_postgresql_flexible_server_database" "retailbot" {
  name      = "retailbot"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Store database credentials in Key Vault
resource "azurerm_key_vault_secret" "db_connection_string" {
  name         = "db-connection-string"
  value        = "postgresql://${var.admin_username}:${urlencode(random_password.postgresql_admin_password.result)}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/retailbot?sslmode=require"
  key_vault_id = var.key_vault_id

  depends_on = [azurerm_postgresql_flexible_server.main]
}