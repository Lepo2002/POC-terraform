output "load_balancer_ip" {
  description = "Indirizzo IP del Load Balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_name" {
  description = "Nome del Load Balancer"
  value       = "${var.environment}-lb"
}

output "backend_service_id" {
  description = "ID del Backend Service"
  value       = google_compute_backend_service.backend_service.id
}

output "url_map_id" {
  description = "ID della URL Map"
  value       = google_compute_url_map.url_map.id
}

output "http_proxy_id" {
  description = "ID del HTTP Proxy"
  value       = google_compute_target_http_proxy.http_proxy.id
}

output "https_proxy_id" {
  description = "ID del HTTPS Proxy"
  value       = var.enable_https ? google_compute_target_https_proxy.https_proxy[0].id : ""
}