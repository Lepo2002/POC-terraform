variable "project_id" {
  description = "ID del progetto GCP in cui creare il backend"
  type        = string
}

variable "region" {
  description = "Regione GCP predefinita"
  type        = string
  default     = "europe-west1"
}

variable "bucket_name" {
  description = "Nome del bucket per lo stato Terraform. Se vuoto, sarà generato un nome con un suffisso casuale"
  type        = string
  default     = ""
}

variable "bucket_location" {
  description = "Location del bucket GCS (regionale o multi-regionale)"
  type        = string
  default     = "EU"
}

variable "state_history_days" {
  description = "Numero di giorni per mantenere le versioni precedenti dello stato"
  type        = number
  default     = 30
}

variable "force_destroy" {
  description = "Se consentire la distruzione del bucket anche se contiene oggetti"
  type        = bool
  default     = false
}

variable "bucket_admins" {
  description = "Lista di membri con accesso amministrativo al bucket"
  type        = list(string)
  default     = []
}

variable "bucket_users" {
  description = "Lista di membri con accesso in lettura/scrittura agli oggetti nel bucket"
  type        = list(string)
  default     = []
}

variable "create_datastore_lock" {
  description = "Se creare un database Firestore per il locking dello stato"
  type        = bool
  default     = true
}

variable "datastore_location" {
  description = "Location del database Firestore"
  type        = string
  default     = "eur3"
}

variable "generate_backend_file" {
  description = "Se generare un file backend.tf nella directory corrente"
  type        = bool
  default     = true
}

variable "generate_environment_files" {
  description = "Se generare un template di backend per gli ambienti"
  type        = bool
  default     = true
}

variable "generate_lock_script" {
  description = "Se generare uno script per l'applicazione con locking"
  type        = bool
  default     = true
}