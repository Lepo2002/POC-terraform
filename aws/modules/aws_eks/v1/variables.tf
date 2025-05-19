
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.27"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the EKS cluster"
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Enable private API server endpoint"
  default     = true
}

variable "enable_public_endpoint" {
  type        = bool
  description = "Enable public API server endpoint"
  default     = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs"
  default     = []
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 4
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "instance_types" {
  type        = list(string)
  description = "List of instance types for the worker nodes"
  default     = ["t3.medium"]
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
