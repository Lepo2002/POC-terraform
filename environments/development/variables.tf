variable "project_name" {
  description = "Nome del progetto"
  type        = string
}

variable "azure_region" {
  description = "Regione primaria Azure"
  type        = string
  default     = "westeurope"
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

variable "gcp_service_account_email" {
  description = "The email of the GCP service account."
  type        = string
}