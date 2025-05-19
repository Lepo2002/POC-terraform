provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_project_service" "storage_api" {
  project = var.project_id
  service = "storage-api.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "datastore_api" {
  project = var.project_id
  service = "datastore.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_storage_bucket" "terraform_state" {
  name          = var.bucket_name != "" ? var.bucket_name : "terraform-state-${var.project_id}-${random_id.bucket_suffix.hex}"
  project       = var.project_id
  location      = var.bucket_location
  force_destroy = var.force_destroy

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.state_history_days
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true

  depends_on = [google_project_service.storage_api]
}

resource "google_storage_bucket_iam_binding" "terraform_state_admin" {
  bucket  = google_storage_bucket.terraform_state.name
  role    = "roles/storage.admin"
  members = var.bucket_admins
}

resource "google_storage_bucket_iam_binding" "terraform_state_user" {
  bucket  = google_storage_bucket.terraform_state.name
  role    = "roles/storage.objectAdmin"
  members = var.bucket_users
}

resource "google_firestore_database" "terraform_lock" {
  count     = var.create_datastore_lock ? 1 : 0
  project   = var.project_id
  name      = "(default)"
  location_id = var.datastore_location
  type      = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.datastore_api]
}

resource "local_file" "backend_config" {
  count    = var.generate_backend_file ? 1 : 0
  content  = <<-EOT
terraform {
  backend "gcs" {
    bucket  = "${google_storage_bucket.terraform_state.name}"
    prefix  = "terraform/state"
  }
}
EOT
  filename = "${path.module}/backend.tf"
}

resource "local_file" "backend_template" {
  count    = var.generate_environment_files ? 1 : 0
  content  = <<-EOT

terraform {
  backend "gcs" {
    bucket  = "${google_storage_bucket.terraform_state.name}"
    prefix  = "terraform/state/ENVIRONMENT_NAME"
  }
}
EOT
  filename = "${path.module}/backend_template.tf"
}

resource "local_file" "apply_with_locks_script" {
  count    = var.generate_lock_script ? 1 : 0
  content  = <<-EOT
#!/bin/bash

set -e

ENVIRONMENT=$${1:-development}
LOCK_ID="terraform-\$ENVIRONMENT-lock"
PROJECT_ID="${var.project_id}"
BUCKET="${google_storage_bucket.terraform_state.name}"

echo "Attempting to acquire lock for environment: \$ENVIRONMENT..."

EXISTING_LOCK=$(gcloud firestore documents get projects/$PROJECT_ID/databases/(default)/documents/terraform-locks/$LOCK_ID 2>/dev/null || echo "")

if [ -n "$EXISTING_LOCK" ]; then
  echo "Lock already exists. Cannot proceed. Please wait until the lock is released."
  exit 1
fi

gcloud firestore documents create "projects/$PROJECT_ID/databases/(default)/documents/terraform-locks" --document-id="$LOCK_ID" --field="timestamp=$(date +%s)" --field="user=$(whoami)" --field="environment=$ENVIRONMENT"

echo "Lock acquired. Proceeding with Terraform apply..."

cd environments/$ENVIRONMENT

terraform init -backend-config="bucket=$BUCKET" -backend-config="prefix=terraform/state/$ENVIRONMENT"
terraform apply

gcloud firestore documents delete "projects/$PROJECT_ID/databases/(default)/documents/terraform-locks/$LOCK_ID"

echo "Lock released. Terraform apply completed."
EOT
  filename = "${path.module}/../scripts/apply_with_locks.sh"
  file_permission = "0755"
}