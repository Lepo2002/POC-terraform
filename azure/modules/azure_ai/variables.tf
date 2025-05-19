variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["development", "testing", "production"], var.environment)
    error_message = "L'ambiente deve essere uno tra: development, testing, production."
  }
}

variable "account_name" {
  type = string
}

variable "account_kind" {
  type    = string
  default = "Cognitive"
  validation {
    condition     = contains(["Cognitive", "OpenAI", "Speech"], var.account_kind)
    error_message = "account_kind deve essere Cognitive, OpenAI, o Speech."
  }
}

variable "sku_name" {
  type    = string
  default = "S0"
}

variable "custom_subdomain_name" {
  type    = string
  default = null
}

variable "model_deployments" {
  type = map(object({
    model_format    = string
    model_name      = string
    model_version   = string
    scale_type      = string
    scale_capacity  = number
  }))
  default = {}
}

variable "network_default_action" {
  type    = string
  default = "Deny"
}

variable "network_subnet_ids" {
  type    = list(string)
  default = []
}

variable "network_ip_rules" {
  type    = list(string)
  default = []
}

variable "enable_customer_managed_key" {
  type    = bool
  default = false
}

variable "customer_managed_key_id" {
  type    = string
  default = null
}

variable "enable_private_endpoint" {
  type    = bool
  default = false
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}

variable "additional_tags" {
  type    = map(string)
  default = {}
}