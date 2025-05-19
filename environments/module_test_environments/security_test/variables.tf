variable "gcp_project_id" {
  description = "The GCP project ID to use for testing"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region to deploy test resources"
  type        = string
  default     = "europe-west1"
}

variable "gcp_service_account" {
  description = "The GCP service account to use for testing"
  type        = string
}

variable "azure_region" {
  description = "The Azure region to deploy test resources"
  type        = string
  default     = "westeurope"
}

variable "azure_tenant_id" {
  description = "The Azure tenant ID for Key Vault and identity testing"
  type        = string
}

variable "azure_object_id" {
  description = "The Azure object ID (user or service principal) to grant access to Key Vault"
  type        = string
}

variable "security_contact_email" {
  description = "Email address for security contact"
  type        = string
  default     = "security@example.com"
}

variable "security_contact_phone" {
  description = "Phone number for security contact"
  type        = string
  default     = "+123456789"
}