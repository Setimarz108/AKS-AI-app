variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "retailbot"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "database_subnet_id" {
  description = "Subnet ID for database"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for PostgreSQL"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "retailbotadmin"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768  # 32GB
}

variable "sku_name" {
  description = "SKU name for PostgreSQL server"
  type        = string
  default     = "GP_Standard_D2s_v3"  # General Purpose, 2 vCPU, 8GB RAM
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}# terraform/modules/database/variables.tf

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "delegated_subnet_id" {
  description = "The ID of the subnet delegated for PostgreSQL"
  type        = string
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone for PostgreSQL"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  default     = "retailbotadmin"
  
  validation {
    condition     = length(var.admin_username) >= 1 && length(var.admin_username) <= 63
    error_message = "Admin username must be between 1 and 63 characters."
  }
}

variable "database_name" {
  description = "Name of the application database"
  type        = string
  default     = "retailbot"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}