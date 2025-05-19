output "bucket_name" {
  description = "Nome del bucket GCS creato per lo stato Terraform"
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_url" {
  description = "URL del bucket GCS"
  value       = google_storage_bucket.terraform_state.url
}

output "backend_config" {
  description = "Configurazione backend da utilizzare"
  value       = {
    bucket = google_storage_bucket.terraform_state.name
    prefix = "terraform/state"
  }
}

output "firestore_database" {
  description = "Database Firestore configurato per il locking"
  value       = var.create_datastore_lock ? google_firestore_database.terraform_lock[0].name : null
}

output "backend_setup_instructions" {
  description = "Istruzioni per configurare il backend negli ambienti"
  value       = <<-EOT
    Per utilizzare questo backend Terraform:
    
    1. In ogni directory dell'ambiente, crea un file 'backend.tf' con:
       
       terraform {
         backend "gcs" {
           bucket  = "${google_storage_bucket.terraform_state.name}"
           prefix  = "terraform/state/ENVIRONMENT_NAME"
         }
       }
       
    2. Inizializza Terraform in ogni ambiente con:
       
       terraform init
       
    3. Per applicare con locking, utilizza lo script generato:
       
       ../scripts/apply_with_locks.sh [environment]
  EOT
}