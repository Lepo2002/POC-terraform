
variable "project_id" {
  type        = string
  description = "ID del progetto GCP"
}

variable "vpc_network" {
  type        = string
  description = "Nome della VPC network"
}

variable "firewall_rules" {
  type = map(object({
    description        = string
    direction         = string
    priority          = number
    source_ranges     = optional(list(string))
    destination_ranges = optional(list(string))
    source_tags       = optional(list(string))
    target_tags       = optional(list(string))
    enable_logging    = optional(bool, false)
    
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
  }))
  description = "Mappa delle regole firewall da creare"
}
