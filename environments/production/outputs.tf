output "azure_resource_group_name" {
  description = "Nome del resource group Azure"
  value       = module.azure_core.resource_group_name
}

output "azure_resource_group_id" {
  description = "ID del resource group Azure"
  value       = module.azure_core.resource_group_id
}

output "azure_vnet_id" {
  description = "ID della VNet Azure principale"
  value       = module.azure_networking.vnet_id
}

output "azure_vnet_address_space" {
  description = "Spazio di indirizzi della VNet Azure"
  value       = module.azure_networking.vnet_address_space
}

output "azure_subnet_ids" {
  description = "Mappa di IDs delle subnet Azure"
  value       = module.azure_networking.subnet_ids
}

output "azure_dr_vnet_id" {
  description = "ID della VNet Azure di disaster recovery"
  value       = var.enable_disaster_recovery ? module.azure_networking_dr[0].vnet_id : null
}

output "azure_database_fully_qualified_domain_name" {
  description = "Nome di dominio completo del database Azure"
  value       = module.azure_database.fully_qualified_domain_name
}

output "azure_kubernetes_id" {
  description = "ID del cluster Kubernetes Azure"
  value       = module.azure_kubernetes.cluster_id
}

output "azure_kubernetes_fqdn" {
  description = "FQDN del cluster Kubernetes Azure"
  value       = module.azure_kubernetes.fqdn
}

output "azure_kubernetes_kubelet_identity" {
  description = "Identity del kubelet AKS"
  value       = module.azure_kubernetes.kubelet_identity_object_id
}

output "azure_storage_account_name" {
  description = "Nome dell'account di storage Azure"
  value       = module.azure_storage.storage_account_name
}

output "azure_cognitive_account_endpoint" {
  description = "Endpoint dell'account Cognitive Services"
  value       = module.azure_ai.cognitive_account_endpoint
  sensitive   = true
}

output "azure_backup_vault_id" {
  description = "ID del Recovery Services Vault"
  value       = azurerm_recovery_services_vault.backup_vault.id
}

output "gcp_project_id" {
  description = "ID del progetto GCP"
  value       = module.gcp_project.project_id
}

output "gcp_project_number" {
  description = "Numero del progetto GCP"
  value       = module.gcp_project.project_number
}

output "gcp_vpc_name" {
  description = "Nome della VPC GCP"
  value       = module.gcp_networking.vpc_name
}

output "gcp_vpc_id" {
  description = "ID della VPC GCP"
  value       = module.gcp_networking.vpc_id
}

output "gcp_subnet_ids" {
  description = "Mappa di IDs delle subnet GCP"
  value       = module.gcp_networking.subnet_ids
}

output "gcp_nat_ip" {
  description = "IP del NAT gateway GCP"
  value       = module.gcp_networking.nat_ip
}

output "gcp_database_instance_name" {
  description = "Nome dell'istanza database GCP"
  value       = module.gcp_database.instance_name
}

output "gcp_database_connection_name" {
  description = "Nome di connessione del database GCP"
  value       = module.gcp_database.connection_name
}

output "gcp_kubernetes_name" {
  description = "Nome del cluster Kubernetes GCP"
  value       = module.gcp_kubernetes.cluster_name
}

output "gcp_kubernetes_endpoint" {
  description = "Endpoint del cluster Kubernetes GCP"
  value       = module.gcp_kubernetes.cluster_endpoint
  sensitive   = true
}

output "gcp_kubernetes_command_line" {
  description = "Comando per connessione al cluster GKE"
  value       = module.gcp_kubernetes.gke_command_line
}

output "gcp_loadbalancer_ip" {
  description = "Indirizzo IP del load balancer GCP"
  value       = module.gcp_loadbalancer.load_balancer_ip
}

output "gcp_service_account_email" {
  description = "Email del service account principale"
  value       = module.gcp_iam.service_account_email
}

output "gcp_security_key_ring_name" {
  description = "Nome del key ring KMS in GCP"
  value       = module.gcp_security.key_ring_name
}

output "gcp_security_crypto_key_ids" {
  description = "ID delle chiavi di crittografia in GCP"
  value       = module.gcp_security.crypto_key_ids
}

output "multi_cloud_interconnect" {
  description = "Dettagli dell'interconnessione multi-cloud"
  value = {
    gcp_interconnect_id        = module.multi_cloud_interconnect.gcp_interconnect_id
    gcp_interconnect_self_link = module.multi_cloud_interconnect.gcp_interconnect_self_link
    azure_express_route_id     = module.multi_cloud_interconnect.azure_express_route_id
  }
  sensitive = true
}

output "multi_cloud_identity_federation" {
  description = "Dettagli della federazione delle identità tra cloud"
  value = {
    gcp_identity_pool_id       = module.multi_cloud_identity_federation.gcp_identity_pool_id
    azure_app_id               = module.multi_cloud_identity_federation.azure_app_id
    azure_managed_identity_id  = module.multi_cloud_identity_federation.azure_managed_identity_id
  }
}