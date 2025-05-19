provider "azurerm" {
  features {}
}

provider "azuread" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
    },
    var.additional_tags
  )
}

resource "azurerm_management_lock" "resource_group_lock" {
  count      = var.enable_resource_lock ? 1 : 0
  name       = "${var.resource_group_name}-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = var.lock_level
  notes      = "This Resource Group is locked to prevent accidental deletion"
}

resource "azurerm_role_assignment" "role_assignments" {
  for_each = var.role_assignments

  scope                = azurerm_resource_group.main.id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}

resource "azurerm_policy_assignment" "group_policies" {
  for_each = var.policy_assignments

  name                 = each.key
  scope                = azurerm_resource_group.main.id
  policy_definition_id = each.value.policy_definition_id
  description          = each.value.description

  identity {
    type = "SystemAssigned"
  }
}