# Generate random suffix for unique names
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "cr${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = var.tags
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Key Vault for secrets
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable soft delete and purge protection for production
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # Set to true in production

  # Network ACLs - restrict access to specific networks
  network_acls {
    default_action = "Allow"  # For demo; use "Deny" in production with specific allow rules
    bypass         = "AzureServices"
  }

  # Access policy for current user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }

  tags = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"
  # kubernetes_version  = var.kubernetes_version  # Let Azure choose default

  # Network configuration - Fixed CIDR overlap
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    service_cidr      = "172.16.0.0/16"     # Non-overlapping range
    dns_service_ip    = "172.16.0.10"       # Must be within service_cidr
  }

  # System node pool
  default_node_pool {
    name                = "system"
  
    vm_size             = "Standard_D2s_v3"
    vnet_subnet_id      = var.aks_subnet_id
    type                = "VirtualMachineScaleSets"
    
    # Auto-scaling configuration
    enable_auto_scaling = true
    min_count          = 1
    max_count          = 3
  }

  # Identity configuration
  identity {
    type = "SystemAssigned"
  }

  # Monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  tags = var.tags
}

# Role assignment for ACR - allows AKS to pull images
resource "azurerm_role_assignment" "aks_to_acr" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
