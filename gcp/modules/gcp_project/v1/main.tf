resource "google_folder" "project_folder" {
  display_name = var.folder_name
  parent       = "organizations/${var.organization_id}"
}

resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  folder_id       = google_folder.project_folder.name
  billing_account = var.billing_account
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "google_project_service" "project_services" {
  for_each = toset(var.enabled_apis)
  
  project = google_project.project.project_id
  service = each.value
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_compute_project_metadata_item" "project_metadata" {
  for_each = var.project_metadata
  
  project = google_project.project.project_id
  key     = each.key
  value   = each.value
}

resource "google_resource_manager_lien" "project_lien" {
  count        = var.enable_lien ? 1 : 0
  parent       = "projects/${google_project.project.number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "terraform-managed"
  reason       = "Prevenire la cancellazione accidentale del progetto"
}