# terraform/main.tf

terraform {
  required_version = ">= 1.6.0"
    backend "azurerm" {
    storage_account_name = "tfstate4690"  
    container_name       = "tfstate"
    key                  = "retailbot.tfstate"
    
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.80"
    }

    
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true  # For demo environments
    }
  }
}

locals {
  project_name = "retailbot"
  environment  = "demo"
  location     = "West Europe"
  
  common_tags = {
    Project      = local.project_name
    Environment  = local.environment
    ManagedBy    = "Terraform"
    CostCenter   = "Demo"
    Architecture = "ContainerInstances"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.project_name}-${local.environment}"
  location = local.location
  tags     = local.common_tags
}

# Networking module
module "networking" {
  source = "./modules/networking"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = local.common_tags
}

# Key Vault module for secure secret management
module "keyvault" {
  source = "./modules/keyvault"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = local.common_tags
}

# Database module for persistent data storage
module "database" {
  source = "./modules/database"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
 
  admin_username         = "retailbotadmin"
  database_name         = "retailbot"
  backup_retention_days = 7
  
  tags = local.common_tags
}

# data "azurerm_postgresql_flexible_server" "existing" {
#   name                = "psql-retailbot-demo-9zn0"
#   resource_group_name = azurerm_resource_group.main.name
# }

# # Set a known database password in Key Vault
# resource "azurerm_key_vault_secret" "database_password" {
#   name         = "database-password"
#   value        = "RetailBot2025!"
#   key_vault_id = module.keyvault.key_vault_id
# }

# # Create the database connection string
# locals {
#   database_connection_string = "postgresql://retailbotadmin:RetailBot2025!@${data.azurerm_postgresql_flexible_server.existing.fqdn}:5432/retailbot?sslmode=require"
# }

# Container Instances module
module "container_instances" {
  source = "./modules/container_instances"
  
  project_name        = local.project_name
  environment         = local.environment
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Reference Key Vault for secrets
  key_vault_id = module.keyvault.key_vault_id

  frontend_image_tag = var.frontend_image_tag
  backend_image_tag  = var.backend_image_tag
  
    # Add database connection details
  #  database_url = module.database.connection_string 

  # Resource allocation
  backend_cpu     = "0.5"
  backend_memory  = "1.0"
  frontend_cpu    = "0.5"
  frontend_memory = "1.0"
  log_level       = "INFO"
  
  tags = local.common_tags
  
  depends_on = [module.keyvault,module.database]
}
