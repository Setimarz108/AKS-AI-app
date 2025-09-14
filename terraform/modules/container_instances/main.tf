# terraform/modules/container_instances/main.tf - Unified Container Group

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

# Get the OpenAI API key from Key Vault
data "azurerm_key_vault_secret" "openai_api_key" {
  name         = "openai-api-key"
  key_vault_id = var.key_vault_id
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "cr${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  
  tags = var.tags
}

# Unified Container Group with both frontend and backend
resource "azurerm_container_group" "app" {
  name                = "ci-${var.project_name}-app-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = "${var.project_name}-app-${random_string.suffix.result}"
  os_type             = "Linux"
  restart_policy      = "Always"
  
  tags = var.tags

  # Backend Container
  container {
    name   = "backend"
    image  = "${azurerm_container_registry.main.login_server}/retailbot-api:${var.backend_image_tag}"
    cpu    = var.backend_cpu
    memory = var.backend_memory

    ports {
      port     = 8000
      protocol = "TCP"
    }

    environment_variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.log_level
      # DATABASE_URL = var.database_url != "" ? var.database_url : null
    }

    secure_environment_variables = {
      OPENAI_API_KEY = data.azurerm_key_vault_secret.openai_api_key.value
    }

    liveness_probe {
      http_get {
        path   = "/health"
        port   = 8000
        scheme = "Http"
      }
      initial_delay_seconds = 30
      period_seconds       = 10
      timeout_seconds      = 5
      failure_threshold    = 3
    }

    readiness_probe {
      http_get {
        path   = "/health"
        port   = 8000
        scheme = "Http"
      }
      initial_delay_seconds = 10
      period_seconds       = 5
      timeout_seconds      = 3
      failure_threshold    = 3
    }
  }

  # Frontend Container
  container {
    name   = "frontend"
    image  = "${azurerm_container_registry.main.login_server}/retailbot-frontend:${var.frontend_image_tag}"
    cpu    = var.frontend_cpu
    memory = var.frontend_memory

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      ENVIRONMENT = var.environment
    }

    liveness_probe {
      http_get {
        path   = "/"
        port   = 80
        scheme = "Http"
      }
      initial_delay_seconds = 30
      period_seconds       = 10
      timeout_seconds      = 5
      failure_threshold    = 3
    }

    readiness_probe {
      http_get {
        path   = "/"
        port   = 80
        scheme = "Http"
      }
      initial_delay_seconds = 10
      period_seconds       = 5
      timeout_seconds      = 3
      failure_threshold    = 3
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username  
    password = azurerm_container_registry.main.admin_password
  }
}