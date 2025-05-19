variable "environment" {
  description = "Ambiente di deployment"
  type        = string
}

variable "resource_group_name" {
  description = "Nome del resource group"
  type        = string
}

variable "location" {
  description = "Location Azure"
  type        = string
}

variable "vnet_name" {
  description = "Nome della Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Lista di indirizzi CIDR per la VNet"
  type        = list(string)
}

variable "dns_servers" {
  description = "Lista di DNS server IP"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Lista di subnet da creare"
  type = list(object({
    name             = string
    address_prefix   = string
    service_endpoints = optional(list(string))
    delegation       = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
  }))
  default = []
}

variable "network_security_groups" {
  description = "Lista di NSG da creare"
  type = list(object({
    name = string
  }))
  default = []
}

variable "security_rules" {
  description = "Lista di regole NSG"
  type = list(object({
    name                       = string
    nsg_name                   = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

variable "subnet_nsg_associations" {
  description = "Lista di associazioni subnet-NSG"
  type = list(object({
    subnet_name = string
    nsg_name    = string
  }))
  default = []
}

variable "route_tables" {
  description = "Lista di route table"
  type = list(object({
    name                         = string
    disable_bgp_route_propagation = optional(bool)
  }))
  default = []
}

variable "routes" {
  description = "Lista di route"
  type = list(object({
    name                 = string
    route_table_name     = string
    address_prefix       = string
    next_hop_type        = string
    next_hop_in_ip_address = optional(string)
  }))
  default = []
}

variable "subnet_route_table_associations" {
  description = "Lista di associazioni subnet-route table"
  type = list(object({
    subnet_name      = string
    route_table_name = string
  }))
  default = []
}

variable "public_ips" {
  description = "Lista di IP pubblici"
  type = list(object({
    name              = string
    allocation_method = string
    sku               = string
  }))
  default = []
}

variable "nat_gateways" {
  description = "Lista di NAT gateway"
  type = list(object({
    name = string
  }))
  default = []
}

variable "nat_gateway_public_ip_associations" {
  description = "Lista di associazioni NAT gateway-IP pubblico"
  type = list(object({
    nat_gateway_name = string
    public_ip_name   = string
  }))
  default = []
}

variable "subnet_nat_gateway_associations" {
  description = "Lista di associazioni subnet-NAT gateway"
  type = list(object({
    subnet_name      = string
    nat_gateway_name = string
  }))
  default = []
}

variable "private_dns_zones" {
  description = "Lista di private DNS zone"
  type        = list(string)
  default     = []
}

variable "private_dns_vnet_links" {
  description = "Lista di link private DNS zone-VNet"
  type = list(object({
    dns_zone_name        = string
    vnet_name            = string
    registration_enabled = bool
  }))
  default = []
}

variable "vnet_peerings" {
  description = "Lista di VNet peering"
  type = list(object({
    name                         = string
    remote_vnet_id               = string
    allow_virtual_network_access = optional(bool)
    allow_forwarded_traffic      = optional(bool)
    allow_gateway_transit        = optional(bool)
    use_remote_gateways          = optional(bool)
  }))
  default = []
}

variable "application_security_groups" {
  description = "Lista di Application Security Group"
  type = list(object({
    name = string
  }))
  default = []
}

variable "firewall" {
  description = "Configurazione di Azure Firewall"
  type = object({
    name           = string
    sku_name       = string
    sku_tier       = string
    subnet_name    = string
    public_ip_name = string
  })
  default = null
}

variable "firewall_network_rule_collections" {
  description = "Collezioni di regole network per Firewall"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      source_addresses      = list(string)
      destination_addresses = list(string)
      destination_ports     = list(string)
      protocols             = list(string)
    }))
  }))
  default = []
}

variable "firewall_application_rule_collections" {
  description = "Collezioni di regole applicative per Firewall"
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name             = string
      source_addresses = list(string)
      target_fqdns     = optional(list(string))
      fqdn_tags        = optional(list(string))
      protocol = object({
        port = number
        type = string
      })
    }))
  }))
  default = []
}

variable "virtual_network_gateway" {
  description = "Configurazione di Virtual Network Gateway"
  type = object({
    name          = string
    type          = string
    vpn_type      = string
    sku           = string
    active_active = bool
    enable_bgp    = bool
    subnet_name   = string
    public_ip_name = string
  })
  default = null
}

variable "express_route" {
  description = "Configurazione di ExpressRoute Circuit"
  type = object({
    name                  = string
    service_provider_name = string
    peering_location      = string
    bandwidth_in_mbps     = number
    tier                  = string
    family                = string
  })
  default = null
}

variable "ddos_protection_plan" {
  description = "Configurazione di DDoS Protection Plan"
  type = object({
    name = string
  })
  default = null
}

variable "bastion_host" {
  description = "Configurazione di Azure Bastion"
  type = object({
    name           = string
    subnet_name    = string
    public_ip_name = string
  })
  default = null
}

variable "tags" {
  description = "Mappa di tag"
  type        = map(string)
  default     = {}
}