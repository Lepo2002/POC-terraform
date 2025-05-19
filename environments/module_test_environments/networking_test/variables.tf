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