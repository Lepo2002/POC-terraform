
variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "cluster_name" {
  description = "Nome del cluster GKE"
  type        = string
}

variable "region" {
  description = "Regione GCP per il cluster"
  type        = string
}

variable "zone" {
  description = "Zona GCP per il cluster"
  type        = string
}

variable "regional" {
  description = "Se true, crea un cluster regionale"
  type        = bool
  default     = true
}

variable "network" {
  description = "Nome della rete VPC"
  type        = string
}

variable "subnetwork" {
  description = "Nome della subnet"
  type        = string
}

variable "kubernetes_version" {
  description = "Versione di Kubernetes"
  type        = string
  default     = "latest"
}

variable "initial_node_count" {
  description = "Numero iniziale di nodi per pool"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Numero minimo di nodi per autoscaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Numero massimo di nodi per autoscaling"
  type        = number
  default     = 5
}

variable "machine_type" {
  description = "Tipo di macchina per i nodi"
  type        = string
  default     = "e2-medium"
}

variable "preemptible" {
  description = "Usa istanze preemptible"
  type        = bool
  default     = false
}

variable "enable_private_nodes" {
  description = "Abilita nodi privati"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Abilita endpoint privato"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "Blocco CIDR per il master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "cluster_secondary_range_name" {
  description = "Nome del range secondario per i pod"
  type        = string
}

variable "services_secondary_range_name" {
  description = "Nome del range secondario per i servizi"
  type        = string
}

variable "master_authorized_networks" {
  description = "Reti autorizzate per accedere al master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "node_labels" {
  description = "Label da applicare ai nodi"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags da applicare ai nodi"
  type        = list(string)
  default     = []
}
