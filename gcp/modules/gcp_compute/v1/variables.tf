variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "vm_name" {
  description = "Nome base per le istanze VM"
  type        = string
}

variable "zone" {
  description = "Zona GCP per le VM"
  type        = string
}

variable "machine_type" {
  description = "Tipo di macchina per le VM"
  type        = string
  default     = "e2-medium"
}

variable "disk_image" {
  description = "Immagine per il disco di boot"
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "disk_size" {
  description = "Dimensione del disco in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Tipo di disco (pd-standard, pd-balanced, pd-ssd)"
  type        = string
  default     = "pd-standard"
}

variable "disk_name" {
  description = "Nome base per i dischi"
  type        = string
}

variable "network_id" {
  description = "ID della rete VPC"
  type        = string
}

variable "subnetwork_id" {
  description = "ID della subnet"
  type        = string
}

variable "service_account_email" {
  description = "Email del service account da utilizzare"
  type        = string
}

variable "service_account_scopes" {
  description = "Scopes per il service account"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "ssh_user" {
  description = "Username SSH"
  type        = string
  default     = "admin"
}

variable "ssh_pub_key_file" {
  description = "Path al file della chiave pubblica SSH"
  type        = string
}

variable "instance_count" {
  description = "Numero di istanze VM da creare"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Ambiente di deployment"
  type        = string
}

variable "additional_tags" {
  description = "Tag aggiuntivi da applicare alle VM"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Se true, assegna un indirizzo IP pubblico alle VM"
  type        = bool
  default     = true
}

variable "startup_script" {
  description = "Script di startup per le VM"
  type        = string
  default     = ""
}

variable "preemptible" {
  description = "Se true, crea istanze preemptible"
  type        = bool
  default     = false
}

variable "additional_disks" {
  description = "Mappa di dischi aggiuntivi da creare"
  type = map(object({
    type = string
    size = number
  }))
  default = {}
}

variable "disk_attachments" {
  description = "Lista di configurazioni per collegare dischi aggiuntivi alle VM"
  type = list(object({
    disk_name     = string
    instance_index = number
    device_name   = string
    mode          = string
  }))
  default = []
}