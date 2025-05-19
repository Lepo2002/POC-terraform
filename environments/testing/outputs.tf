output "azure_resource_group_name" {
  description = "Nome del resource group Azure"
  value       = module.azure_core.resource_group_name
}

output "gcp_project_id" {
  description = "ID del progetto GCP"
  value       = module.gcp_project.project_id
}

output "azure_networking_vnet_id" {
  description = "ID della VNet Azure"
  value       = module.azure_networking.vnet_id
}

output "gcp_networking_vpc_id" {
  description = "ID della VPC GCP"
  value       = module.gcp_networking.vpc_id
}

output "azure_database_connection_string" {
  description = "Stringa di connessione database Azure"
  value       = module.azure_database.connection_string
  sensitive   = true
}

output "gcp_database_connection_name" {
  description = "Nome di connessione database GCP"
  value       = module.gcp_database.connection_name
}

output "azure_kubernetes_cluster_name" {
  description = "Nome del cluster Kubernetes Azure"
  value       = module.azure_kubernetes.cluster_name
}

output "gcp_kubernetes_cluster_name" {
  description = "Nome del cluster Kubernetes GCP"
  value       = module.gcp_kubernetes.cluster_name
}

output "multi_cloud_interconnect_details" {
  description = "Dettagli dell'interconnessione multi-cloud"
  value = {
    gcp_interconnect_id = module.multi_cloud_interconnect.gcp_interconnect_id
    azure_express_route_id = module.multi_cloud_interconnect.azure_express_route_id
  }
  sensitive = true
}