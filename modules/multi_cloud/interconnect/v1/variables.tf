variable "environment" {
  description = "Ambiente di deployment (e.g., development, testing, production)"
  type        = string
}

variable "gcp_project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "gcp_region" {
  description = "Regione GCP"
  type        = string
}

variable "gcp_network_id" {
  description = "ID della rete VPC su GCP"
  type        = string
}

variable "gcp_router_id" {
  description = "ID del router Cloud Router su GCP"
  type        = string
}

variable "interconnect_name" {
  description = "Nome base dell'interconnessione"
  type        = string
  default     = "cloud-interconnect"
}

variable "enable_encryption" {
  description = "Se abilitare la crittografia per l'interconnessione"
  type        = bool
  default     = true
}

variable "edge_availability_domain" {
  description = "Dominio di disponibilità dell'edge (AVAILABILITY_DOMAIN_1 o AVAILABILITY_DOMAIN_2)"
  type        = string
  default     = "AVAILABILITY_DOMAIN_1"
}

variable "ipsec_internal_addresses" {
  description = "Mappa degli indirizzi IPsec interni"
  type = map(object({
    address      = string
    address_type = string
    subnetwork   = string
  }))
  default = {}
}

variable "create_azure_express_route" {
  description = "Se creare un circuito Azure Express Route"
  type        = bool
  default     = true
}

variable "azure_resource_group_name" {
  description = "Nome del resource group Azure"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Location Azure"
  type        = string
  default     = ""
}

variable "express_route_name" {
  description = "Nome del circuito Express Route"
  type        = string
  default     = "express-route"
}

variable "azure_peering_location" {
  description = "Location di peering per Express Route"
  type        = string
  default     = "Amsterdam"
}

variable "azure_bandwidth_mbps" {
  description = "Larghezza di banda del circuito Express Route in Mbps"
  type        = number
  default     = 1000
}

variable "azure_express_route_tier" {
  description = "Tier del circuito Express Route (Standard o Premium)"
  type        = string
  default     = "Standard"
}

variable "create_azure_vpn_backup" {
  description = "Se creare un gateway VPN di backup su Azure"
  type        = bool
  default     = false
}

variable "create_gcp_vpn_backup" {
  description = "Se creare un gateway VPN di backup su GCP"
  type        = bool
  default     = false
}

variable "azure_vpn_public_ip_id" {
  description = "ID dell'indirizzo IP pubblico per il gateway VPN Azure"
  type        = string
  default     = ""
}

variable "azure_gateway_subnet_id" {
  description = "ID della subnet del gateway Azure"
  type        = string
  default     = ""
}

variable "azure_vpn_root_cert" {
  description = "Certificato root per la configurazione client VPN di Azure"
  type        = string
  default     = ""
  sensitive   = true
}

variable "azure_vpn_ip_1" {
  description = "Primo indirizzo IP del gateway VPN Azure"
  type        = string
  default     = ""
}

variable "azure_vpn_ip_2" {
  description = "Secondo indirizzo IP del gateway VPN Azure"
  type        = string
  default     = ""
}

variable "vpn_shared_secret" {
  description = "Segreto condiviso per i tunnel VPN"
  type        = string
  default     = ""
  sensitive   = true
}