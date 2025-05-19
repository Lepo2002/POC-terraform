variable "environment" {
  description = "Ambiente di deployment (e.g., development, testing, production)"
  type        = string
}

variable "gcp_project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "gcp_project_number" {
  description = "Numero del progetto GCP (necessario per gli URI di redirect)"
  type        = string
}

variable "create_gcp_identity_pool" {
  description = "Se creare un pool di identità Workload Identity su GCP"
  type        = bool
  default     = true
}

variable "identity_pool_name" {
  description = "Nome base del pool di identità Workload Identity"
  type        = string
  default     = "azure-identity-pool"
}

variable "federated_sa_name" {
  description = "Nome base del service account per identità federata"
  type        = string
  default     = "federated-sa"
}

variable "gcp_sa_roles" {
  description = "Lista dei ruoli da assegnare al service account su GCP"
  type        = list(string)
  default     = [
    "roles/storage.objectViewer",
    "roles/pubsub.subscriber"
  ]
}

variable "azure_tenant_id" {
  description = "ID del tenant Azure AD"
  type        = string
}

variable "azure_identity_filter" {
  description = "Filtro opzionale per limitare le identità Azure che possono impersonare il service account GCP"
  type        = string
  default     = ""
}

variable "create_azure_app" {
  description = "Se creare un'applicazione Azure AD per l'integrazione"
  type        = bool
  default     = true
}

variable "create_azure_managed_identity" {
  description = "Se creare una managed identity su Azure"
  type        = bool
  default     = false
}

variable "azure_resource_group_name" {
  description = "Nome del resource group Azure (richiesto se create_azure_managed_identity = true)"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Location Azure (richiesto se create_azure_managed_identity = true)"
  type        = string
  default     = ""
}


variable "azure_identity_roles" {
  description = "Lista dei ruoli da assegnare alla managed identity Azure"
    type        = list(string)  
    default     = [         
        "Contributor"        
        ]
}   
