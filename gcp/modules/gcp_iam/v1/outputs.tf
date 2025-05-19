output "service_account_id" {
  description = "ID del service account creato"
  value       = google_service_account.main.id
}

output "service_account_email" {
  description = "Email del service account creato"
  value       = google_service_account.main.email
}

output "service_account_name" {
  description = "Nome completo del service account creato"
  value       = google_service_account.main.name
}

output "service_account_key" {
  description = "Chiave privata del service account in formato JSON (se creata)"
  value       = var.create_service_account_key ? google_service_account_key.main[0].private_key : null
  sensitive   = true
}

output "service_account_key_id" {
  description = "ID della chiave del service account (se creata)"
  value       = var.create_service_account_key ? google_service_account_key.main[0].id : null
}

output "workload_identity_enabled" {
  description = "Se Workload Identity è abilitato"
  value       = var.enable_workload_identity
}

output "custom_roles_created" {
  description = "Lista dei ruoli IAM personalizzati creati"
  value       = [for role in google_project_iam_custom_role.custom_roles : role.id]
}