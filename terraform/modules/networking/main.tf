# terraform/modules/networking/main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.80"
    }
  }
}

# Virtual Network for future extensibility
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Subnet for potential database integration
resource "azurerm_subnet" "database" {
  name                 = "snet-${var.project_name}-database-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
  
  delegation {
    name = "database-delegation"
    
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Private DNS Zone for database (if needed later)
resource "azurerm_private_dns_zone" "database" {
  name                = "${var.project_name}-${var.environment}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = "link-${var.project_name}-${var.environment}"
  private_dns_zone_name = azurerm_private_dns_zone.database.name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = var.resource_group_name
  registration_enabled  = false
  
  tags = var.tags
}

# Network Security Group for future use
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  tags = var.tags
}

# Default security rules for HTTPS/HTTP
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "AllowHTTPS"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "AllowHTTP"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}