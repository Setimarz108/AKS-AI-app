# terraform/modules/container_instances/variables.tf

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

# Key Vault integration variables
variable "key_vault_id" {
  description = "The ID of the Key Vault containing secrets"
  type        = string
}

variable "backend_cpu" {
  description = "CPU allocation for backend container"
  type        = string
  default     = "0.5"
}

variable "backend_memory" {
  description = "Memory allocation for backend container"
  type        = string
  default     = "1.0"
}

variable "frontend_cpu" {
  description = "CPU allocation for frontend container"
  type        = string
  default     = "0.5"
}

variable "frontend_memory" {
  description = "Memory allocation for frontend container"
  type        = string
  default     = "1.0"
}

variable "log_level" {
  description = "Log level for the application"
  type        = string
  default     = "INFO"
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "frontend_image_tag" {
  description = "Frontend image tag to deploy (e.g., v1.0.0)"
  type        = string
}

variable "backend_image_tag" {
  description = "Backend image tag to deploy (e.g., v1.0.0)"
  type        = string
}
variable "database_name" {
  description = "Database name"
  type        = string
  default     = ""
}

variable "database_username" {
  description = "Database username"
  type        = string
  default     = ""
}

variable "database_password" {
  description = "Database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_server_fqdn" {
  description = "Database server FQDN"
  type        = string
  default     = ""
}