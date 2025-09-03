# terraform/modules/keyvault/outputs.tf

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# output "openai_secret_name" {
#   description = "The name of the OpenAI API key secret"
#   value       = var.openai_api_key != null ? azurerm_key_vault_secret.openai_api_key[0].name : null
# }

# output "openai_secret_id" {
#   description = "The ID of the OpenAI API key secret"
#   value       = var.openai_api_key != null ? azurerm_key_vault_secret.openai_api_key[0].id : null
# }

output "additional_secret_names" {
  description = "The names of additional secrets stored in Key Vault"
  value       = keys(var.additional_secrets)
}