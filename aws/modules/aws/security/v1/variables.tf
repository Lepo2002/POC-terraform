
variable "environment" {
  type        = string
  description = "Environment name"
}

variable "name" {
  type        = string
  description = "Security group name"
}

variable "description" {
  type        = string
  description = "Security group description"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where to create the security group"
}

variable "ingress_rules" {
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string))
  }))
  description = "List of ingress rules"
  default     = []
}

variable "egress_rules" {
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    security_groups = optional(list(string))
  }))
  description = "List of egress rules"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags for the security group"
  default     = {}
}
