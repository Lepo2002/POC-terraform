output "vpc_id" {
  description = "ID della VPC creata"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Nome della VPC creata"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "Self-link della VPC creata"
  value       = google_compute_network.vpc.self_link
}

output "subnet_ids" {
  description = "Mappa dei nomi delle subnet ai loro ID"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.id }
}

output "subnet_self_links" {
  description = "Mappa dei nomi delle subnet ai loro self-link"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.self_link }
}

output "subnet_regions" {
  description = "Mappa dei nomi delle subnet alle loro regioni"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.region }
}

output "subnet_cidrs" {
  description = "Mappa dei nomi delle subnet ai loro range CIDR"
  value       = { for name, subnet in google_compute_subnetwork.subnets : name => subnet.ip_cidr_range }
}

output "nat_ip" {
  description = "IP del NAT gateway (se creato)"
  value       = var.create_nat_gateway ? google_compute_router_nat.nat[0].nat_ips : null
}

output "router_id" {
  description = "ID del router (se creato)"
  value       = var.create_nat_gateway ? google_compute_router.router[0].id : null
}

output "private_service_connect_id" {
  description = "ID della connessione di servizio privato (se creata)"
  value       = var.create_private_service_access ? google_service_networking_connection.private_service_connection[0].id : null
}

output "private_ip_allocation_id" {
  description = "ID dell'allocazione IP privata (se creata)"
  value       = var.create_private_service_access ? google_compute_global_address.private_ip_alloc[0].id : null
}