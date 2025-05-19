output "user_assigned_identity_ids" {
  description = "Mappa dei nomi delle identità ai loro ID"
  value       = { for name, identity in azurerm_user_assigned_identity.user_identities : name => identity.id }
}

output "user_assigned_identity_principal_ids" {
  description = "Mappa dei nomi delle identità ai loro Principal ID"
  value       = { for name, identity in azurerm_user_assigned_identity.user_identities : name => identity.principal_id }
}

output "user_assigned_identity_client_ids" {
  description = "Mappa dei nomi delle identità ai loro Client ID"
  value       = { for name, identity in azurerm_user_assigned_identity.user_identities : name => identity.client_id }
}

output "application_ids" {
  description = "Mappa dei nomi delle app ai loro Application ID"
  value       = { for name, app in azuread_application.applications : name => app.application_id }
}

output "application_object_ids" {
  description = "Mappa dei nomi delle app ai loro Object ID"
  value       = { for name, app in azuread_application.applications : name => app.object_id }
}

output "service_principal_ids" {
  description = "Mappa dei nomi delle app ai loro Service Principal ID"
  value       = { for name, sp in azuread_service_principal.service_principals : name => sp.object_id }
}

output "application_secrets" {
  description = "Mappa dei nomi delle app ai loro segreti (sensibile)"
  value       = { for name, secret in azuread_application_password.app_passwords : name => secret.value }
  sensitive   = true
}

output "group_ids" {
  description = "Mappa dei nomi dei gruppi ai loro Object ID"
  value       = { for name, group in azuread_group.groups : name => group.object_id }
}

output "group_object_ids" {
  description = "Lista di tutti gli Object ID dei gruppi creati"
  value       = [for group in azuread_group.groups : group.object_id]
}

output "custom_role_ids" {
  description = "Mappa dei nomi dei ruoli personalizzati ai loro ID"
  value       = { for name, role in azurerm_role_definition.custom_roles : name => role.role_definition_id }
}