
variable "filename" {
  type        = string
  description = "Path to the function's deployment package"
}

variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "handler" {
  type        = string
  description = "Function entrypoint in your code"
}

variable "runtime" {
  type        = string
  description = "Runtime environment for the Lambda function"
}

variable "timeout" {
  type        = number
  default     = 3
  description = "Function timeout in seconds"
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "Amount of memory in MB for the function"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Environment variables for the function"
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet IDs for VPC configuration"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "List of security group IDs for VPC configuration"
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "CloudWatch log retention in days"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
