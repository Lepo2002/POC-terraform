variable "gcp_project_id" {
  description = "The GCP project ID to use for testing"
  type        = string
}

variable "gcp_project_number" {
  description = "The GCP project number (required for identity federation)"
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

variable "azure_tenant_id" {
  description = "The Azure tenant ID for identity federation testing"
  type        = string
}

variable "azure_subscription_id" {
  description = "The Azure subscription ID for role assignments"
  type        = string
}

variable "vpn_shared_secret" {
  description = "Shared secret for VPN tunnel testing"
  type        = string
  sensitive   = true
}