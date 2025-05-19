variable "project_id" {
  description = "ID del progetto GCP in cui creare il load balancer"
  type        = string
}

variable "environment" {
  description = "Ambiente di deployment"
  type        = string
}

variable "instance_group_1" {
  description = "URL del gruppo di istanze primario"
  type        = string
}

variable "instance_group_2" {
  description = "URL del gruppo di istanze secondario (opzionale)"
  type        = string
  default     = ""
}

variable "region" {
  description = "Regione GCP"
  type        = string
}

variable "network_id" {
  description = "ID della rete VPC"
  type        = string
  default     = ""
}

variable "enable_https" {
  description = "Abilitare HTTPS"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Nome di dominio per il certificato SSL"
  type        = string
}

variable "health_check_interval" {
  description = "Intervallo di health check in secondi"
  type        = number
  default     = 5
}

variable "health_check_timeout" {
  description = "Timeout di health check in secondi"
  type        = number
  default     = 5
}

variable "health_check_port" {
  description = "Porta per l'health check"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path per l'health check"
  type        = string
  default     = "/"
}

variable "target_tags" {
  description = "Tag per le regole firewall"
  type        = list(string)
  default     = ["http-server", "https-server"]
}

variable "security_policy" {
  description = "ID della policy di sicurezza (Cloud Armor)"
  type        = string
  default     = ""
}

variable "enable_session_affinity" {
  description = "Abilitare l'affinità di sessione"
  type        = bool
  default     = false
}

variable "enable_cdn" {
  description = "Abilitare Cloud CDN"
  type        = bool
  default     = false
}

variable "enable_iap" {
  description = "Abilitare Identity-Aware Proxy"
  type        = bool
  default     = false
}

variable "iap_oauth2_client_id" {
  description = "Client ID OAuth2 per IAP"
  type        = string
  default     = ""
}

variable "iap_oauth2_client_secret" {
  description = "Client Secret OAuth2 per IAP"
  type        = string
  default     = ""
  sensitive   = true
}