variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "service_account_name" {
  description = "Nome del service account da creare"
  type        = string
}

variable "environment" {
  description = "Ambiente di deployment (e.g., development, testing, production)"
  type        = string
}

variable "service_account_roles" {
  description = "Lista dei ruoli IAM da assegnare al service account"
  type        = list(string)
  default     = [
    "roles/compute.admin",
    "roles/container.admin",
    "roles/storage.admin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}

variable "create_service_account_key" {
  description = "Se true, crea una chiave per il service account"
  type        = bool
  default     = false
}

variable "custom_roles" {
  description = "Mappa di ruoli IAM predefiniti e i membri a cui assegnarli"
  type        = map(list(string))
  default     = {}
}

variable "custom_role_definitions" {
  description = "Mappa di definizioni di ruoli IAM personalizzati da creare"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
    stage       = string
  }))
  default = {}
}

variable "enable_workload_identity" {
  description = "Se true, abilita Workload Identity per l'integrazione con GKE"
  type        = bool
  default     = false
}

variable "workload_identity_bindings" {
  description = "Mappa dei namespace Kubernetes alle entità a cui concedere l'accesso Workload Identity"
  type        = map(list(string))
  default     = {}
}

variable "storage_bucket_bindings" {
  description = "Mappa dei bucket Storage e i membri a cui assegnare i ruoli"
  type = map(object({
    role    = string
    members = list(string)
  }))
  default = {}
}

variable "enable_audit_logging" {
  description = "Se true, configura l'audit logging per il progetto"
  type        = bool
  default     = false
}

variable "audit_services" {
  description = "Mappa dei servizi da sottoporre ad audit e le relative configurazioni"
  type        = map(map(list(string)))
  default     = {
    "allServices" = {
      "DATA_READ"  = []
      "DATA_WRITE" = []
      "ADMIN_READ" = []
    }
  }
}