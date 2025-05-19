
variable "firewall_name" {
  type        = string
  description = "Nome del firewall Azure"
}

variable "location" {
  type        = string
  description = "Location Azure per il firewall"
}

variable "resource_group_name" {
  type        = string
  description = "Nome del resource group"
}

variable "subnet_id" {
  type        = string
  description = "ID della subnet per il firewall"
}

variable "public_ip_address_id" {
  type        = string
  description = "ID dell'IP pubblico per il firewall"
}

variable "sku_name" {
  type        = string
  default     = "AZFW_VNet"
  description = "SKU name del firewall"
}

variable "sku_tier" {
  type        = string
  default     = "Standard"
  description = "SKU tier del firewall"
}

variable "environment" {
  type        = string
  description = "Environment tag"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags aggiuntivi"
}

variable "application_rules" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name              = string
      source_addresses  = list(string)
      destination_fqdns = list(string)
      protocol = object({
        type = string
        port = number
      })
    }))
  }))
  default     = []
  description = "Regole applicative del firewall"
}

variable "network_rules" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
      protocols            = list(string)
    }))
  }))
  default     = []
  description = "Regole di rete del firewall"
}
