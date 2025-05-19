variable "environment" {
  description = "Ambiente di deployment (e.g., development, testing, production)"
  type        = string
}

variable "resource_group_name" {
  description = "Nome del resource group Azure in cui creare l'account di storage"
  type        = string
}

variable "location" {
  description = "Location Azure per l'account di storage"
  type        = string
}

variable "storage_account_name" {
  description = "Nome dell'account di storage Azure (deve essere globalmente univoco)"
  type        = string
}

variable "account_tier" {
  description = "Tier dell'account di storage (Standard o Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Tipo di replicazione per l'account di storage (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Tipo di account di storage (StorageV2, Storage, BlobStorage, BlockBlobStorage o FileStorage)"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Tier di accesso per l'account di storage (Hot o Cool)"
  type        = string
  default     = "Hot"
}

variable "enable_https_traffic_only" {
  description = "Se abilitare solo il traffico HTTPS per l'account di storage"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "La versione minima di TLS supportata dall'account di storage"
  type        = string
  default     = "TLS1_2"
}

variable "allow_public_access" {
  description = "Se consentire l'accesso pubblico anonimo ai contenitori e ai blob"
  type        = bool
  default     = false
}

variable "enable_hierarchical_namespace" {
  description = "Se abilitare il namespace gerarchico (ADLS Gen2)"
  type        = bool
  default     = false
}

variable "enable_nfsv3" {
  description = "Se abilitare il supporto per NFS 3.0"
  type        = bool
  default     = false
}

variable "blob_cors_rules" {
  description = "Regole CORS per il servizio Blob"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

variable "enable_blob_versioning" {
  description = "Se abilitare il versioning per i blob"
  type        = bool
  default     = false
}

variable "enable_change_feed" {
  description = "Se abilitare il change feed per le operazioni sui blob"
  type        = bool
  default     = false
}

variable "enable_last_access_time_tracking" {
  description = "Se abilitare il tracking dell'ultimo accesso ai blob"
  type        = bool
  default     = false
}

variable "blob_soft_delete_retention_days" {
  description = "Numero di giorni per il retention dei blob eliminati (0 per disabilitare)"
  type        = number
  default     = 0
}

variable "container_soft_delete_retention_days" {
  description = "Numero di giorni per il retention dei container eliminati (0 per disabilitare)"
  type        = number
  default     = 0
}

variable "network_default_action" {
  description = "Azione predefinita per le regole di rete (Allow o Deny)"
  type        = string
  default     = "Deny"
}

variable "network_bypass" {
  description = "Servizi che possono bypassare le regole di rete (AzureServices, Logging, Metrics, None)"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "ip_rules" {
  description = "Lista di indirizzi IP o CIDR che possono accedere all'account di storage"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Lista di ID di subnet che possono accedere all'account di storage"
  type        = list(string)
  default     = []
}

variable "enable_static_website" {
  description = "Se abilitare l'hosting di siti web statici"
  type        = bool
  default     = false
}

variable "static_website_index_document" {
  description = "Nome del documento index per il sito web statico"
  type        = string
  default     = "index.html"
}

variable "static_website_error_document" {
  description = "Nome del documento di errore per il sito web statico"
  type        = string
  default     = "404.html"
}

variable "containers" {
  description = "Lista di container blob da creare"
  type = list(object({
    name        = string
    access_type = string
  }))
  default = []
}

variable "file_shares" {
  description = "Lista di file share da creare"
  type = list(object({
    name        = string
    quota       = number
    access_tier = string 
    permissions = string 
    start_date  = string 
    expiry_date = string 
  }))
  default = []
}

variable "tables" {
  description = "Lista di nomi di tabelle da creare"
  type        = list(string)
  default     = []
}

variable "queues" {
  description = "Lista di nomi di code da creare"
  type        = list(string)
  default     = []
}

variable "blob_data_contributors" {
  description = "Lista di ID principali a cui assegnare il ruolo Storage Blob Data Contributor"
  type        = list(string)
  default     = []
}

variable "blob_data_readers" {
  description = "Lista di ID principali a cui assegnare il ruolo Storage Blob Data Reader"
  type        = list(string)
  default     = []
}

variable "lifecycle_rules" {
  description = "Regole del ciclo di vita per i blob"
  type = list(object({
    name        = string
    prefix_match = list(string)
    blob_types  = list(string)
    base_blob   = object({
      tier_to_cool_after_days    = number
      tier_to_archive_after_days = number
      delete_after_days          = number
    })
    snapshot    = object({
      delete_after_days = number
    })
    version     = object({
      delete_after_days = number
    })
  }))
  default = []
}

variable "enable_advanced_threat_protection" {
  description = "Se abilitare Advanced Threat Protection"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Se creare un private endpoint per l'account di storage"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "ID della subnet in cui creare il private endpoint"
  type        = string
  default     = null
}

variable "private_endpoint_subresources" {
  description = "Lista di subresource da connettere tramite private endpoint (blob, file, table, queue)"
  type        = list(string)
  default     = ["blob"]
}

variable "private_dns_zone_id" {
  description = "ID della private DNS zone per il private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Mappa di tag da applicare all'account di storage"
  type        = map(string)
  default     = {}
}

variable "prevent_destroy" {
  description = "Se impedire la distruzione dell'account di storage"
  type        = bool
  default     = false
}