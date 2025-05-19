output "gcp_interconnect_id" {
  description = "ID dell'interconnessione GCP"
  value       = google_compute_interconnect_attachment.gcp_interconnect.id
}

output "gcp_interconnect_self_link" {
  description = "Self-link dell'interconnessione GCP"
  value       = google_compute_interconnect_attachment.gcp_interconnect.self_link
}

output "gcp_interconnect_pairing_key" {
  description = "Chiave di pairing dell'interconnessione (da utilizzare con Azure)"
  value       = google_compute_interconnect_attachment.gcp_interconnect.pairing_key
}

output "azure_express_route_id" {
  description = "ID del circuito Express Route Azure (se creato)"
  value       = var.create_azure_express_route ? azurerm_express_route_circuit.azure_express_route[0].id : null
}

output "azure_express_route_service_key" {
  description = "Service key del circuito Express Route Azure (se creato)"
  value       = var.create_azure_express_route ? azurerm_express_route_circuit.azure_express_route[0].service_key : null
  sensitive   = true
}

output "azure_express_route_authorization_key" {
  description = "Chiave di autorizzazione del circuito Express Route (se creato)"
  value       = var.create_azure_express_route ? azurerm_express_route_circuit_authorization.azure_auth[0].authorization_key : null
  sensitive   = true
}

output "gcp_vpn_gateway_id" {
  description = "ID del gateway VPN GCP (se creato)"
  value       = var.create_gcp_vpn_backup ? google_compute_ha_vpn_gateway.gcp_vpn_gateway[0].id : null
}

output "azure_vpn_gateway_id" {
  description = "ID del gateway VPN Azure (se creato)"
  value       = var.create_azure_vpn_backup ? azurerm_virtual_network_gateway.azure_vpn_gateway[0].id : null
}

output "gcp_vpn_tunnel_ids" {
  description = "IDs dei tunnel VPN GCP (se creati)"
  value       = var.create_gcp_vpn_backup ? [
    google_compute_vpn_tunnel.gcp_vpn_tunnel_1[0].id,
    google_compute_vpn_tunnel.gcp_vpn_tunnel_2[0].id
  ] : null
}