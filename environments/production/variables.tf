variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "azure_region" {
  description = "Regione primaria Azure"
  type        = string
  default     = "westeurope"
}

variable "azure_dr_region" {
  description = "Regione di disaster recovery Azure"
  type        = string
  default     = "northeurope"
}

variable "azure_platform_admin_id" {
  description = "ID principale amministratore piattaforma Azure"
  type        = string
}

variable "gcp_project_id" {
  description = "ID progetto GCP"
  type        = string
}

variable "gcp_region" {
  description = "Regione primaria GCP"
  type        = string
  default     = "europe-west1"
}

variable "gcp_dr_region" {
  description = "Regione di disaster recovery GCP"
  type        = string
  default     = "europe-west4"
}

variable "gcp_organization_id" {
  description = "ID organizzazione GCP"
  type        = string
}

variable "gcp_billing_account" {
  description = "Account di fatturazione GCP"
  type        = string
}

variable "database_admin_username" {
  description = "Username amministratore database"
  type        = string
}

variable "database_admin_password" {
  description = "Password amministratore database"
  type        = string
  sensitive   = true
}

variable "vpn_shared_secret" {
  description = "Segreto condiviso per VPN"
  type        = string
  sensitive   = true
}

variable "alert_email" {
  description = "Email per avvisi"
  type        = string
}

variable "slack_channel" {
  description = "Canale Slack per notifiche"
  type        = string
}

variable "slack_token" {
  description = "Token Slack"
  type        = string
  sensitive   = true
}

variable "enable_full_ha" {
  description = "Abilita configurazione completa ad alta disponibilità"
  type        = bool
  default     = true
}

variable "enable_disaster_recovery" {
  description = "Abilita configurazione di disaster recovery"
  type        = bool
  default     = true
}

variable "bastion_admin_cidr" {
  description = "CIDR consentito per accesso amministrativo ai bastion host"
  type        = string
  default     = "10.0.0.0/24"
}