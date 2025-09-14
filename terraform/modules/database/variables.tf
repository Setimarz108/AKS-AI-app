# terraform/modules/database/variables.tf

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
  default     = null
}

variable "private_dns_zone_id" {
  description = "The ID of the private DNS zone for PostgreSQL"
  type        = string
  default     = null
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