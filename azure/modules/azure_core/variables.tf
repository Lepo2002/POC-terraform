variable "resource_group_name" {
  description = "Nome del resource group"
  type        = string
}

variable "location" {
  description = "Regione Azure per le risorse"
  type        = string
}

variable "environment" {
  description = "Ambiente di deployment"
  type        = string
  validation {
    condition     = contains(["development", "testing", "production"], var.environment)
    error_message = "L'ambiente deve essere uno tra: development, testing, production."
  }
}

variable "enable_resource_lock" {
  description = "Abilita il lock sul resource group"
  type        = bool
  default     = false
}

variable "lock_level" {
  description = "Livello di lock per il resource group"
  type        = string
  default     = "CanNotDelete"
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "Il lock_level deve essere CanNotDelete o ReadOnly."
  }
}

variable "additional_tags" {
  description = "Tag aggiuntivi per il resource group"
  type        = map(string)
  default     = {}
}

variable "role_assignments" {
  description = "Mappa di assegnazioni di ruolo"
  type = map(object({
    role          = string
    principal_id  = string
  }))
  default = {}
}

variable "policy_assignments" {
  description = "Mappa di assegnazioni di policy"
  type = map(object({
    policy_definition_id = string
    description          = optional(string)
  }))
  default = {}
}

variable "azure_ad_applications" {
  description = "Applicazioni Azure AD da creare"
  type = list(object({
    display_name     = string
    identifier_uris  = optional(list(string))
    sign_in_audience = optional(string)
    owners           = optional(list(string))
  }))
  default = []
}