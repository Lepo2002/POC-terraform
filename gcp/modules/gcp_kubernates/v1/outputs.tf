output "cluster_id" {
  description = "ID del cluster GKE"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "Nome del cluster GKE"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint del cluster GKE"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Certificato CA del cluster"
  value       = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

output "node_pools" {
  description = "Node pools creati"
  value       = google_container_node_pool.primary_nodes
}

output "cluster_node_pool_id" {
  description = "ID del node pool principale"
  value       = google_container_node_pool.primary_nodes.id
}

output "cluster_location" {
  description = "Location (regione o zona) del cluster"
  value       = google_container_cluster.primary.location
}

output "gke_command_line" {
  description = "Comando per ottenere le credenziali del cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region=${google_container_cluster.primary.location} --project=${var.project_id}"
}

output "dr_cluster_name" {
  description = "Nome del cluster Kubernetes DR"
  value       = var.enable_dr ? google_container_cluster.dr[0].name : ""
}

output "dr_cluster_id" {
  description = "ID univoco del cluster Kubernetes DR"
  value       = var.enable_dr ? google_container_cluster.dr[0].id : ""
}

output "dr_cluster_endpoint" {
  description = "Endpoint per accedere al control plane Kubernetes DR"
  value       = var.enable_dr ? google_container_cluster.dr[0].endpoint : ""
  sensitive   = true
}

output "dr_cluster_location" {
  description = "Location del cluster DR"
  value       = var.enable_dr ? google_container_cluster.dr[0].location : ""
}

output "dr_gke_command_line" {
  description = "Comando per ottenere le credenziali del cluster DR"
  value       = var.enable_dr ? "gcloud container clusters get-credentials ${google_container_cluster.dr[0].name} --region=${google_container_cluster.dr[0].location} --project=${var.project_id}" : ""
}