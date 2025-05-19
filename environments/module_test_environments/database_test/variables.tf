variable "gcp_project_id" {
  description = "The GCP project ID to use for testing"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy test resources"
  type        = string
  default     = "europe-west1"
}

variable "azure_region" {
  description = "The Azure region to deploy test resources"
  type        = string
  default     = "westeurope"
}

variable "database_admin_username" {
  description = "Admin username for database instances"
  type        = string
  default     = "dbadmin"
}

variable "database_admin_password" {
  description = "Admin password for database instances"
  type        = string
  sensitive   = true
}

variable "database_readonly_password" {
  description = "Read-only user password for database instances"
  type        = string
  sensitive   = true
}