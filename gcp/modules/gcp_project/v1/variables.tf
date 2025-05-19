variable "project_name" {
  description = "Nome del progetto GCP"
  type        = string
}

variable "project_id" {
  description = "ID univoco del progetto GCP"
  type        = string
}

variable "organization_id" {
  description = "ID dell'organizzazione GCP"
  type        = string
}

variable "billing_account" {
  description = "ID dell'account di fatturazione GCP"
  type        = string
}

variable "folder_name" {
  description = "Nome della cartella in cui creare il progetto"
  type        = string
}

variable "environment" {
  description = "Ambiente di deployment (e.g., development, testing, production)"
  type        = string
  default     = "development"
}

variable "enabled_apis" {
  description = "Lista delle API GCP da abilitare nel progetto"
  type        = list(string)
  default     = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "iam.googleapis.com",
    "storage-api.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ]
}

variable "project_metadata" {
  description = "Mappa dei metadati da aggiungere al progetto"
  type        = map(string)
  default     = {}
}

variable "enable_lien" {
  description = "Se true, attiva un lien per impedire la cancellazione accidentale del progetto"
  type        = bool
  default     = false
}