provider "azurerm" {
  features {}
}

provider "azuread" {
}

resource "azurerm_user_assigned_identity" "user_identities" {
  for_each = { for identity in var.user_assigned_identities : identity.name => identity }
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_role_assignment" "identity_role_assignments" {
  for_each = {
    for assignment in var.identity_role_assignments :
    "${assignment.identity_name}-${assignment.scope}-${assignment.role_definition_name}" => assignment
  }
  
  principal_id         = azurerm_user_assigned_identity.user_identities[each.value.identity_name].principal_id
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
}

resource "azuread_application" "applications" {
  for_each = { for app in var.azure_ad_applications : app.display_name => app }
  
  display_name     = each.value.display_name
  identifier_uris  = lookup(each.value, "identifier_uris", [])
  sign_in_audience = lookup(each.value, "sign_in_audience", "AzureADMyOrg")
  owners           = lookup(each.value, "owners", [])
  
  dynamic "web" {
    for_each = lookup(each.value, "redirect_uris", null) != null ? [1] : []
    content {
      redirect_uris = each.value.redirect_uris
    }
  }
  
  dynamic "api" {
    for_each = lookup(each.value, "oauth2_permission_scopes", null) != null ? [1] : []
    content {
      dynamic "oauth2_permission_scope" {
        for_each = each.value.oauth2_permission_scopes
        content {
          id                         = oauth2_permission_scope.value.id
          admin_consent_description  = oauth2_permission_scope.value.admin_consent_description
          admin_consent_display_name = oauth2_permission_scope.value.admin_consent_display_name
          user_consent_description   = lookup(oauth2_permission_scope.value, "user_consent_description", oauth2_permission_scope.value.admin_consent_description)
          user_consent_display_name  = lookup(oauth2_permission_scope.value, "user_consent_display_name", oauth2_permission_scope.value.admin_consent_display_name)
          enabled                    = lookup(oauth2_permission_scope.value, "enabled", true)
          type                       = lookup(oauth2_permission_scope.value, "type", "Admin")
        }
      }
    }
  }
  
  dynamic "required_resource_access" {
    for_each = lookup(each.value, "required_resource_access", [])
    content {
      resource_app_id = required_resource_access.value.resource_app_id
      
      dynamic "resource_access" {
        for_each = required_resource_access.value.resource_access
        content {
          id   = resource_access.value.id
          type = resource_access.value.type
        }
      }
    }
  }
}

resource "azuread_service_principal" "service_principals" {
  for_each = { for app in var.azure_ad_applications : app.display_name => app }
  
  client_id                    = azuread_application.applications[each.key].client_id
  app_role_assignment_required = lookup(each.value, "app_role_assignment_required", false)
  
  tags = lookup(each.value, "tags", [])
}

resource "azuread_application_password" "app_passwords" {
  for_each = {
    for app in var.azure_ad_applications :
    app.display_name => app if lookup(app, "create_password", false)
  }
  
  application_id = azuread_application.applications[each.key].application_id
  display_name   = "${each.value.display_name}-secret"
  end_date       = lookup(each.value, "password_end_date", "2024-12-31T23:59:59Z")
}

resource "azurerm_key_vault_secret" "app_secrets" {
  for_each = {
    for app in var.azure_ad_applications :
    app.display_name => app if lookup(app, "create_password", false) && var.key_vault_id != null
  }
  
  name         = "app-${each.value.display_name}-secret"
  value        = azuread_application_password.app_passwords[each.key].value
  key_vault_id = var.key_vault_id
}

resource "azuread_group" "groups" {
  for_each = { for group in var.azure_ad_groups : group.display_name => group }
  
  display_name     = each.value.display_name
  security_enabled = lookup(each.value, "security_enabled", true)
  mail_enabled     = lookup(each.value, "mail_enabled", false)
  owners           = lookup(each.value, "owners", [])
  description      = lookup(each.value, "description", null)
}

resource "azuread_group_member" "group_members" {
  for_each = {
    for membership in var.group_memberships :
    "${membership.group_display_name}-${membership.member_object_id}" => membership
  }
  
  group_object_id  = azuread_group.groups[each.value.group_display_name].object_id
  member_object_id = each.value.member_object_id
}

resource "azurerm_role_assignment" "group_role_assignments" {
  for_each = {
    for assignment in var.group_role_assignments :
    "${assignment.group_display_name}-${assignment.scope}-${assignment.role_definition_name}" => assignment
  }
  
  principal_id         = azuread_group.groups[each.value.group_display_name].object_id
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
}

resource "azurerm_role_assignment" "service_principal_role_assignments" {
  for_each = {
    for assignment in var.service_principal_role_assignments :
    "${assignment.app_display_name}-${assignment.scope}-${assignment.role_definition_name}" => assignment
  }
  
  principal_id         = azuread_service_principal.service_principals[each.value.app_display_name].object_id
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
}

resource "azurerm_role_definition" "custom_roles" {
  for_each = { for role in var.custom_roles : role.name => role }
  
  name        = each.value.name
  scope       = each.value.scope
  description = lookup(each.value, "description", "Custom role created by Terraform")
  
  permissions {
    actions          = lookup(each.value, "actions", [])
    not_actions      = lookup(each.value, "not_actions", [])
    data_actions     = lookup(each.value, "data_actions", [])
    not_data_actions = lookup(each.value, "not_data_actions", [])
  }
  
  assignable_scopes = lookup(each.value, "assignable_scopes", [each.value.scope])
}