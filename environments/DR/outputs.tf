output "azure_resource_group_name" {
  description = "Nome del resource group Azure"
  value       = module.azure_core.resource_group_name
}

output "azure_resource_group_id" {
  description = "ID del resource group Azure"
  value       = module.azure_core.resource_group_id
}

output "azure_vnet_id" {
  description = "ID della VNet Azure DR"
  value       = module.azure_networking.vnet_id
}

output "azure_vnet_address_space" {
  description = "Spazio di indirizzi della VNet Azure DR"
  value       = module.azure_networking.vnet_address_space
}

output "azure_subnet_ids" {
  description = "Mappa di IDs delle subnet Azure DR"
  value       = module.azure_networking.subnet_ids
}

output "azure_database_fully_qualified_domain_name" {
  description = "Nome di dominio completo del database Azure DR"
  value       = module.azure_database.fully_qualified_domain_name
}

output "azure_geo_replica_database_id" {
  description = "ID del database di replica geografica"
  value       = azurerm_mssql_database.geo_replica.id
}

output "azure_kubernetes_id" {
  description = "ID del cluster Kubernetes Azure DR"
  value       = module.azure_kubernetes.cluster_id
}

output "azure_kubernetes_fqdn" {
  description = "FQDN del cluster Kubernetes Azure DR"
  value       = module.azure_kubernetes.fqdn
}

output "azure_storage_account_name" {
  description = "Nome dell'account di storage Azure DR"
  value       = module.azure_storage.storage_account_name
}

output "azure_cognitive_account_endpoint" {
  description = "Endpoint dell'account Cognitive Services DR"
  value       = module.azure_ai.cognitive_account_endpoint
  sensitive   = true
}

output "gcp_project_id" {
  description = "ID del progetto GCP DR"
  value       = module.gcp_project.project_id
}

output "gcp_project_number" {
  description = "Numero del progetto GCP DR"
  value       = module.gcp_project.project_number
}

output "gcp_vpc_name" {
  description = "Nome della VPC GCP DR"
  value       = module.gcp_networking.vpc_name
}

output "gcp_vpc_id" {
  description = "ID della VPC GCP DR"
  value       = module.gcp_networking.vpc_id
}

output "gcp_subnet_ids" {
  description = "Mappa di IDs delle subnet GCP DR"
  value       = module.gcp_networking.subnet_ids
}

output "gcp_nat_ip" {
  description = "IP del NAT gateway GCP DR"
  value       = module.gcp_networking.nat_ip
}

output "gcp_database_instance_name" {
  description = "Nome dell'istanza database GCP DR"
  value       = module.gcp_database.instance_name
}

output "gcp_database_connection_name" {
  description = "Nome di connessione del database GCP DR"
  value       = module.gcp_database.connection_name
}

output "gcp_database_replica_id" {
  description = "ID dell'istanza di replica del database GCP"
  value       = google_sql_database_instance.replica.id
}

output "gcp_kubernetes_name" {
  description = "Nome del cluster Kubernetes GCP DR"
  value       = module.gcp_kubernetes.cluster_name
}

output "gcp_kubernetes_endpoint" {
  description = "Endpoint del cluster Kubernetes GCP DR"
  value       = module.gcp_kubernetes.cluster_endpoint
  sensitive   = true
}

output "gcp_kubernetes_command_line" {
  description = "Comando per connessione al cluster GKE DR"
  value       = module.gcp_kubernetes.gke_command_line
}

output "gcp_loadbalancer_ip" {
  description = "Indirizzo IP del load balancer GCP DR"
  value       = module.gcp_loadbalancer.load_balancer_ip
}

output "gcp_service_account_email" {
  description = "Email del service account principale DR"
  value       = module.gcp_iam.service_account_email
}

output "production_azure_vnet" {
  description = "Informazioni sulla VNet Azure di produzione"
  value = {
    id   = data.azurerm_virtual_network.prod_vnet.id
    name = data.azurerm_virtual_network.prod_vnet.name
  }
}

output "production_gcp_vpc" {
  description = "Informazioni sulla VPC GCP di produzione"
  value = {
    id        = data.google_compute_network.prod_vpc.id
    self_link = data.google_compute_network.prod_vpc.self_link
  }
}

output "vpc_peering_status" {
  description = "Stato del peering VPC con l'ambiente di produzione"
  value = {
    azure_peering_id = azurerm_virtual_network_peering.dr_to_prod.id
    gcp_peering_id   = google_compute_network_peering.dr_to_prod.id
  }
}