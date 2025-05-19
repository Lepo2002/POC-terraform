variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "network_id" {
  description = "ID della rete VPC"
  type        = string
}

variable "environment" {
  description = "Ambiente (development, testing, production)"
  type        = string
  validation {
    condition     = contains(["development", "testing", "production"], var.environment)
    error_message = "L'ambiente deve essere uno tra: development, testing, production."
  }
}

variable "common_rules" {
  description = "Regole firewall comuni per tutti gli ambienti"
  type = map(object({
    direction     = string
    source_ranges = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
    target_tags  = list(string)
    description  = string
  }))
  default = {}
}

variable "environment_rules" {
  description = "Regole firewall specifiche per ambiente"
  type = map(map(object({
    direction     = string
    source_ranges = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
    target_tags  = list(string)
    description  = string
  })))
  default = {
    development = {}
    testing     = {}
    production  = {}
  }
}