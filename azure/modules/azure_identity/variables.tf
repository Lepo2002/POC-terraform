variable "environment" {
  description = "Ambiente di deployment"
  type        = string
}

variable "resource_group_name" {
  description = "Nome del resource group"
  type        = string
}

variable "location" {
  description = "Location Azure"
  type        = string
}

variable "user_assigned_identities" {
  description = "Lista di user assigned managed identities da creare"
  type = list(object({
    name = string
  }))
  default = []
}

variable "identity_role_assignments" {
  description = "Lista di assegnazioni di ruolo per le identità"
  type = list(object({
    identity_name        = string
    scope                = string
    role_definition_name = string
  }))
  default = []
}

variable "azure_ad_applications" {
  description = "Lista di applicazioni Azure AD da creare"
  type = list(object({
    display_name     = string
    identifier_uris  = optional(list(string))
    sign_in_audience = optional(string)
    redirect_uris    = optional(list(string))
    owners           = optional(list(string))
    tags             = optional(list(string))
    app_role_assignment_required = optional(bool)
    create_password  = optional(bool)
    password_end_date_relative = optional(string)
    oauth2_permission_scopes = optional(list(object({
      id                         = string
      admin_consent_description  = string
      admin_consent_display_name = string
      user_consent_description   = optional(string)
      user_consent_display_name  = optional(string)
      enabled                    = optional(bool)
      type                       = optional(string)
    })))
    required_resource_access = optional(list(object({
      resource_app_id = string
      resource_access = list(object({
        id   = string
        type = string
      }))
    })))
  }))
  default = []
}

variable "azure_ad_groups" {
  description = "Lista di gruppi Azure AD da creare"
  type = list(object({
    display_name     = string
    security_enabled = optional(bool)
    mail_enabled     = optional(bool)
    owners           = optional(list(string))
    description      = optional(string)
  }))
  default = []
}

variable "group_memberships" {
  description = "Lista di appartenenze a gruppi da creare"
  type = list(object({
    group_display_name = string
    member_object_id   = string
  }))
  default = []
}

variable "group_role_assignments" {
  description = "Lista di assegnazioni di ruolo per i gruppi"
  type = list(object({
    group_display_name   = string
    scope                = string
    role_definition_name = string
  }))
  default = []
}

variable "service_principal_role_assignments" {
  description = "Lista di assegnazioni di ruolo per i service principal"
  type = list(object({
    app_display_name     = string
    scope                = string
    role_definition_name = string
  }))
  default = []
}

variable "custom_roles" {
  description = "Lista di ruoli personalizzati da creare"
  type = list(object({
    name              = string
    scope             = string
    description       = optional(string)
    actions           = optional(list(string))
    not_actions       = optional(list(string))
    data_actions      = optional(list(string))
    not_data_actions  = optional(list(string))
    assignable_scopes = optional(list(string))
  }))
  default = []
}

variable "key_vault_id" {
  description = "ID del Key Vault in cui salvare i segreti delle app"
  type        = string
  default     = null
}

variable "tags" {
  description = "Mappa di tag"
  type        = map(string)
  default     = {}
}