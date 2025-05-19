variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "environment" {
  description = "Ambiente di deployment (e.g., development, testing, production)"
  type        = string
}

variable "region" {
  description = "Regione GCP per le risorse regionali"
  type        = string
}

variable "enable_kms" {
  description = "Se abilitare KMS"
  type        = bool
  default     = false
}

variable "crypto_keys" {
  description = "Mappa delle chiavi di crittografia da creare"
  type = map(object({
    rotation_period  = string
    algorithm        = string
    protection_level = string
  }))
  default = {}
}

variable "secrets" {
  description = "Mappa dei segreti da creare"
  type = map(object({
    data             = string
    auto_replication = bool
  }))
  default     = {}
  sensitive   = true
}

variable "secret_access_bindings" {
  description = "Mappa di binding IAM per l'accesso ai segreti"
  type = map(object({
    secret_id = string
    role      = string
    members   = list(string)
  }))
  default = {}
}

variable "enable_binary_authorization" {
  description = "Se abilitare Binary Authorization"
  type        = bool
  default     = false
}

variable "binary_auth_policy_mode" {
  description = "Modalità di valutazione per Binary Authorization (GLOBAL o LOCAL)"
  type        = string
  default     = "GLOBAL"
}

variable "binary_auth_default_rule" {
  description = "Regola di ammissione predefinita (ALWAYS_ALLOW, ALWAYS_DENY, REQUIRE_ATTESTATION)"
  type        = string
  default     = "ALWAYS_ALLOW"
}

variable "binary_auth_enforce" {
  description = "Se applicare forzatamente Binary Authorization"
  type        = bool
  default     = false
}

variable "binary_auth_whitelist_images" {
  description = "Lista di pattern di immagini da consentire"
  type        = list(string)
  default     = []
}

variable "enable_cloud_armor" {
  description = "Se abilitare Cloud Armor"
  type        = bool
  default     = false
}

variable "enable_ddos_protection" {
  description = "Se abilitare la protezione DDoS adattiva"
  type        = bool
  default     = true
}

variable "cloud_armor_rules" {
  description = "Lista di regole Cloud Armor"
  type = list(object({
    action      = string
    priority    = number
    expression  = string
    description = string
  }))
  default = []
}

variable "enable_ssl_policy" {
  description = "Se creare una policy SSL"
  type        = bool
  default     = false
}

variable "ssl_policy_profile" {
  description = "Profilo della policy SSL (COMPATIBLE, MODERN, RESTRICTED o CUSTOM)"
  type        = string
  default     = "MODERN"
}

variable "ssl_min_tls_version" {
  description = "Versione minima TLS (TLS_1_0, TLS_1_1, TLS_1_2)"
  type        = string
  default     = "TLS_1_2"
}

variable "enable_network_security_policies" {
  description = "Se abilitare Network Security Policies"
  type        = bool
  default     = false
}

variable "network_security_policies" {
  description = "Mappa delle Network Security Policies"
  type = map(object({
    description = string
    rules = list(object({
      priority      = number
      description   = string
      ip_protocol   = string
      ports         = list(string)
      src_ip_ranges = list(string)
      dest_ip_ranges = list(string)
      action        = string
    }))
  }))
  default = {}
}