resource "google_service_account" "main" {
  account_id   = var.service_account_name
  display_name = "Service Account per ${var.environment}"
  project      = var.project_id
  description  = "Service Account principale per l'ambiente ${var.environment}"
}

resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(var.service_account_roles)
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.main.email}"
}

resource "google_service_account_key" "main" {
  count              = var.create_service_account_key ? 1 : 0
  service_account_id = google_service_account.main.name
  key_algorithm      = "KEY_ALG_RSA_2048"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_binding" "custom_role_bindings" {
  for_each = var.custom_roles
  
  project = var.project_id
  role    = each.key
  
  members = each.value
}

resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.custom_role_definitions
  
  project     = var.project_id
  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}

resource "google_service_account_iam_binding" "workload_identity" {
  for_each = var.enable_workload_identity ? var.workload_identity_bindings : {}
  
  service_account_id = google_service_account.main.name
  role               = "roles/iam.workloadIdentityUser"
  
  members = each.value
}

resource "google_storage_bucket_iam_binding" "storage_bindings" {
  for_each = var.storage_bucket_bindings
  
  bucket  = each.key
  role    = each.value.role
  members = each.value.members
}

resource "google_project_iam_audit_config" "audit_configs" {
  for_each = var.enable_audit_logging ? var.audit_services : {}
  
  project = var.project_id
  service = each.key
  
  dynamic "audit_log_config" {
    for_each = each.value
    
    content {
      log_type         = audit_log_config.key
      exempted_members = audit_log_config.value
    }
  }
}