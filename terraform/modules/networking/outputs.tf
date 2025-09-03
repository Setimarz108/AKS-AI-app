# terraform/modules/networking/outputs.tf

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "The address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "database_subnet_id" {
  description = "The ID of the database subnet"
  value       = azurerm_subnet.database.id
}

output "database_subnet_name" {
  description = "The name of the database subnet"
  value       = azurerm_subnet.database.name
}

output "private_dns_zone_id" {
  description = "The ID of the private DNS zone"
  value       = azurerm_private_dns_zone.database.id
}

output "private_dns_zone_name" {
  description = "The name of the private DNS zone"
  value       = azurerm_private_dns_zone.database.name
}

output "network_security_group_id" {
  description = "The ID of the network security group"
  value       = azurerm_network_security_group.main.id
}

output "network_security_group_name" {
  description = "The name of the network security group"
  value       = azurerm_network_security_group.main.name
}