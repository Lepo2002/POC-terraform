output "resource_group_id" {
  description = "ID del resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_name" {
  description = "Nome del resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Locazione del resource group"
  value       = azurerm_resource_group.main.location
}

output "resource_lock_id" {
  description = "ID del lock del resource group"
  value       = var.enable_resource_lock ? azurerm_management_lock.resource_group_lock[0].id : null
}

output "role_assignments" {
  description = "Dettagli delle assegnazioni di ruolo"
  value = {
    for k, v in var.role_assignments : k => {
      role         = v.role
      principal_id = v.principal_id
    }
  }
}

output "policy_assignments" {
  description = "Dettagli delle assegnazioni di policy"
  value = {
    for k, v in var.policy_assignments : k => {
      policy_definition_id = v.policy_definition_id
      description          = v.description
    }
  }
}