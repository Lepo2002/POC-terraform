output "project_id" {
  description = "ID del progetto creato"
  value       = google_project.project.project_id
}

output "project_number" {
  description = "Numero del progetto creato"
  value       = google_project.project.number
}

output "project_name" {
  description = "Nome del progetto creato"
  value       = google_project.project.name
}

output "folder_id" {
  description = "ID della cartella creata"
  value       = google_folder.project_folder.id
}

output "folder_name" {
  description = "Nome della cartella creata"
  value       = google_folder.project_folder.display_name
}

output "enabled_apis" {
  description = "Lista delle API abilitate nel progetto"
  value       = [for api in google_project_service.project_services : api.service]
}