output "gcp_identity_pool_id" {
  description = "ID del pool di identità Workload Identity su GCP"
  value       = var.create_gcp_identity_pool ? google_iam_workload_identity_pool.main[0].id : null
}

output "gcp_identity_pool_name" {
  description = "Nome del pool di identità Workload Identity su GCP"
  value       = var.create_gcp_identity_pool ? google_iam_workload_identity_pool.main[0].name : null
}

output "gcp_azure_provider_id" {
  description = "ID del provider Azure per Workload Identity su GCP"
  value       = var.create_gcp_identity_pool ? google_iam_workload_identity_pool_provider.azure_provider[0].id : null
}

output "gcp_federated_sa_email" {
  description = "Email del service account federato su GCP"
  value       = var.create_gcp_identity_pool ? google_service_account.federated_sa[0].email : null
}

output "azure_app_id" {
  description = "ID dell'applicazione creata su Azure AD"
  value       = var.create_azure_app ? azuread_application.gcp_integration[0].application_id : null
}

output "azure_app_object_id" {
  description = "Object ID dell'applicazione creata su Azure AD"
  value       = var.create_azure_app ? azuread_application.gcp_integration[0].object_id : null
}

output "azure_app_secret" {
  description = "Secret dell'applicazione Azure AD (sensibile)"
  value       = var.create_azure_app ? azuread_application_password.gcp_integration_secret[0].value : null
  sensitive   = true
}

output "azure_managed_identity_id" {
  description = "ID della managed identity creata su Azure"
  value       = var.create_azure_managed_identity ? azurerm_user_assigned_identity.azure_identity[0].id : null
}

output "azure_managed_identity_principal_id" {
  description = "Principal ID della managed identity creata su Azure"
  value       = var.create_azure_managed_identity ? azurerm_user_assigned_identity.azure_identity[0].principal_id : null
}

output "azure_managed_identity_client_id" {
  description = "Client ID della managed identity creata su Azure"
  value       = var.create_azure_managed_identity ? azurerm_user_assigned_identity.azure_identity[0].client_id : null
}

output "workload_identity_config_command" {
  description = "Comando per configurare la workload identity nell'applicazione Azure"
  value       = var.create_gcp_identity_pool ? "gcloud iam workload-identity-pools create-cred-config ${google_iam_workload_identity_pool.main[0].name}/providers/azure-${var.environment} --service-account=${google_service_account.federated_sa[0].email} --azure --azure-tenant-id=${var.azure_tenant_id} --output-file=azure-credentials.json" : null
}