variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "retailbot"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

# variable "openai_api_key" {
#   description = "OpenAI API key for AI functionality"
#   type        = string
#   sensitive   = true
  
#   validation {
#     condition     = can(regex("^sk-", var.openai_api_key))
#     error_message = "OpenAI API key must start with 'sk-'."
#   }
# }