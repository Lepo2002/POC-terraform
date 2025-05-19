output "cognitive_account_id" {
  description = "ID dell'account Cognitive"
  value       = azurerm_cognitive_account.main.id
}

output "cognitive_account_endpoint" {
  description = "Endpoint dell'account Cognitive"
  value       = azurerm_cognitive_account.main.endpoint
  sensitive   = true
}

output "cognitive_account_name" {
  description = "Nome dell'account Cognitive"
  value       = azurerm_cognitive_account.main.name
}

output "model_deployment_ids" {
  description = "IDs dei deployment dei modelli"
  value = {
    for k, v in azurerm_cognitive_deployment.model_deployments : 
    k => v.id
  }
}

output "private_endpoint_id" {
  description = "ID dell'endpoint privato"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.ai_private_endpoint[0].id : null
}

output "customer_managed_key_id" {
  description = "ID della chiave gestita dal cliente"
  value       = var.enable_customer_managed_key ? azurerm_cognitive_account_customer_managed_key.cmk[0].id : null
}