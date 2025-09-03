# terraform/modules/keyvault/variables.tf

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

# variable "openai_api_key" {
#   description = "OpenAI API key for AI functionality"
#   type        = string
#   sensitive   = true
#   default     = null
# }

variable "additional_secrets" {
  description = "Additional secrets to store in Key Vault"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "network_default_action" {
  description = "Default action for network access rules"
  type        = string
  default     = "Allow"  # Use "Deny" in production with specific IP allowlists
  
  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "Network default action must be either 'Allow' or 'Deny'."
  }
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed to access Key Vault (when default action is Deny)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}