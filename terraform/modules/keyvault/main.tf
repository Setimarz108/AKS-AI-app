# terraform/modules/keyvault/main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Key Vault for secure secret storage
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable for Container Instances
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  # Soft delete and purge protection
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # Set to true in production

  # Network access rules
  network_acls {
    default_action = var.network_default_action
    bypass         = "AzureServices"
    
    # Add specific IP ranges if needed
    ip_rules = var.allowed_ip_ranges
  }

  tags = var.tags
}

# Access policy for current user/service principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete"
  ]
}

# # Store OpenAI API key in Key Vault
# resource "azurerm_key_vault_secret" "openai_api_key" {
#   count        = var.openai_api_key != null ? 1 : 0
#   name         = "openai-api-key"
#   value        = var.openai_api_key
#   key_vault_id = azurerm_key_vault.main.id

#   depends_on = [azurerm_key_vault_access_policy.current_user]

#   tags = var.tags
# }

# Store other application secrets
# resource "azurerm_key_vault_secret" "app_secrets" {
#   for_each = var.additional_secrets
  
#   name         = each.key
#   value        = each.value
#   key_vault_id = azurerm_key_vault.main.id

#   depends_on = [azurerm_key_vault_access_policy.current_user]

#   tags = var.tags
# }