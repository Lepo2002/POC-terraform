variable "resource_group_name" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_version" {
  type    = string
  default = "12.0"
}

variable "database_tier" {
  type    = string
  default = "Basic"
}

variable "database_username" {
  type = string
}

variable "database_password" {
  type      = string
  sensitive = true
}

variable "private_network" {
  type    = bool
  default = false
}

variable "private_subnet_id" {
  type    = string
  default = null
}

variable "backup_enabled" {
  type    = bool
  default = true
}

variable "authorized_networks" {
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

variable "additional_users" {
  type = map(string)
  default = {}
}

variable "additional_database_flags" {
  type    = map(string)
  default = {}
}