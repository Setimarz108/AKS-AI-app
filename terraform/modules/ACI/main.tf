# terraform/modules/container_instances/main.tf

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

# Container Instance for Backend API
resource "azurerm_container_group" "backend" {
  name                = "ci-${var.project_name}-api-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = "${var.project_name}-api-${random_string.suffix.result}"
  os_type             = "Linux"
  restart_policy      = "Always"
  
  tags = var.tags

  container {
    name   = "retailbot-api"
    image  = "${azurerm_container_registry.main.login_server}/retailbot-api:latest"
    cpu    = var.backend_cpu
    memory = var.backend_memory

    ports {
      port     = 8000
      protocol = "TCP"
    }

    environment_variables = {
      ENVIRONMENT = var.environment
      LOG_LEVEL   = var.log_level
    }

    secure_environment_variables = {
      OPENAI_API_KEY = var.openai_api_key
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

  image_registry_credential {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password = azurerm_container_registry.main.admin_password
  }
}

# Container Instance for Frontend
resource "azurerm_container_group" "frontend" {
  name                = "ci-${var.project_name}-web-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  dns_name_label      = "${var.project_name}-web-${random_string.suffix.result}"
  os_type             = "Linux"
  restart_policy      = "Always"
  
  tags = var.tags

  container {
    name   = "retailbot-frontend"
    image  = "${azurerm_container_registry.main.login_server}/retailbot-frontend:latest"
    cpu    = var.frontend_cpu
    memory = var.frontend_memory

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      REACT_APP_API_URL = "https://${azurerm_container_group.backend.fqdn}:8000"
      ENVIRONMENT       = var.environment
    }

    liveness_probe {
      http_get {
        path   = "/health"
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
        path   = "/health"
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

  depends_on = [azurerm_container_group.backend]
}