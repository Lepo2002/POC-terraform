variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "vpc_name" {
  description = "Nome della VPC"
  type        = string
}

variable "region" {
  description = "Regione GCP principale"
  type        = string
}

variable "routing_mode" {
  description = "Modalità di routing della VPC (REGIONAL o GLOBAL)"
  type        = string
  default     = "GLOBAL"
  
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "La modalità di routing deve essere REGIONAL o GLOBAL."
  }
}

variable "delete_default_routes" {
  description = "Se eliminare le route predefinite all'atto della creazione"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Lista di subnet da creare"
  type = list(object({
    name             = string
    region           = string
    cidr             = string
    secondary_ranges = list(object({
      name = string
      cidr = string
    }))
  }))
}

variable "create_nat_gateway" {
  description = "Se creare un NAT gateway"
  type        = bool
  default     = false
}

variable "create_private_service_access" {
  description = "Se creare un accesso per servizi privati (es. Cloud SQL)"
  type        = bool
  default     = false
}

variable "routes" {
  description = "Mappa di route personalizzate da creare"
  type = map(object({
    destination_range = string
    priority          = number
    next_hop_type     = string
    next_hop_target   = string
    next_hop_zone     = string
  }))
  default = {}
}