variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "environment" {
  description = "Ambiente di deployment (e.g., development, testing, production)"
  type        = string
}

variable "region" {
  description = "Regione GCP per l'istanza database"
  type        = string
}

variable "instance_name" {
  description = "Nome dell'istanza Cloud SQL"
  type        = string
}

variable "database_name" {
  description = "Nome del database da creare"
  type        = string
}

variable "database_version" {
  description = "Versione del database (e.g., POSTGRES_13, MYSQL_8_0)"
  type        = string
}

variable "database_tier" {
  description = "Tier dell'istanza database (e.g., db-f1-micro, db-custom-2-4096)"
  type        = string
}

variable "disk_size" {
  description = "Dimensione del disco in GB"
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "Tipo di disco (PD_SSD, PD_HDD)"
  type        = string
  default     = "PD_SSD"
}

variable "availability_type" {
  description = "Tipo di disponibilità (REGIONAL per alta disponibilità, ZONAL per singola zona)"
  type        = string
  default     = "ZONAL"
}

variable "backup_enabled" {
  description = "Se abilitare i backup automatici"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Orario di inizio per i backup (formato HH:MM)"
  type        = string
  default     = "02:00"
}

variable "backup_location" {
  description = "Posizione geografica per i backup"
  type        = string
  default     = "eu"
}

variable "enable_binary_logging" {
  description = "Se abilitare i log binari per il ripristino point-in-time"
  type        = bool
  default     = true
}

variable "maintenance_day" {
  description = "Giorno della settimana per la finestra di manutenzione (1-7 per Lun-Dom)"
  type        = number
  default     = 1
}

variable "maintenance_hour" {
  description = "Ora del giorno per la finestra di manutenzione (0-23)"
  type        = number
  default     = 2
}

variable "maintenance_update_track" {
  description = "Traccia di aggiornamenti di manutenzione (canary o stable)"
  type        = string
  default     = "stable"
}

variable "private_network" {
  description = "Se utilizzare una connessione privata per l'istanza"
  type        = bool
  default     = false
}

variable "network_id" {
  description = "ID della rete VPC (richiesto se private_network = true)"
  type        = string
  default     = ""
}

variable "authorized_networks" {
  description = "Mappa di reti autorizzate per accedere all'istanza, nel formato nome = cidr"
  type        = map(string)
  default     = {}
}

variable "database_username" {
  description = "Nome utente per il database"
  type        = string
}

variable "database_password" {
  description = "Password per l'utente database"
  type        = string
  sensitive   = true
}

variable "additional_users" {
  description = "Mappa di utenti aggiuntivi nel formato nome = password"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "max_connections" {
  description = "Numero massimo di connessioni contemporanee"
  type        = string
  default     = "100"
}

variable "additional_database_flags" {
  description = "Flag aggiuntivi per il database nel formato nome = valore"
  type        = map(string)
  default     = {}
}

variable "additional_labels" {
  description = "Etichette aggiuntive da applicare all'istanza database"
  type        = map(string)
  default     = {}
}

variable "database_charset" {
  description = "Charset del database"
  type        = string
  default     = "UTF8"
}

variable "database_collation" {
  description = "Collation del database"
  type        = string
  default     = "en_US.UTF8"
}

variable "enable_deletion_protection" {
  description = "Se proteggere l'istanza dalla cancellazione accidentale"
  type        = bool
  default     = true
}

variable "prevent_destroy" {
  description = "Se impedire la distruzione dell'istanza tramite Terraform"
  type        = bool
  default     = false
}