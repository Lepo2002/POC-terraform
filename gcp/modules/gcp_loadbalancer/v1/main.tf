resource "google_compute_global_address" "lb_ip" {
  name        = "${var.environment}-lb-ip"
  project     = var.project_id
  description = "Indirizzo IP globale per il load balancer ${var.environment}"
}

resource "google_compute_global_forwarding_rule" "http" {
  name        = "${var.environment}-http-rule"
  project     = var.project_id
  target      = google_compute_target_http_proxy.http_proxy.id
  port_range  = "80"
  ip_address  = google_compute_global_address.lb_ip.address
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name        = "${var.environment}-http-proxy"
  project     = var.project_id
  url_map     = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "https" {
  count       = var.enable_https ? 1 : 0
  name        = "${var.environment}-https-rule"
  project     = var.project_id
  target      = google_compute_target_https_proxy.https_proxy[0].id
  port_range  = "443"
  ip_address  = google_compute_global_address.lb_ip.address
}

resource "google_compute_target_https_proxy" "https_proxy" {
  count       = var.enable_https ? 1 : 0
  name        = "${var.environment}-https-proxy"
  project     = var.project_id
  url_map     = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_cert[0].id]
}

resource "google_compute_managed_ssl_certificate" "ssl_cert" {
  count       = var.enable_https ? 1 : 0
  name        = "${var.environment}-ssl-cert"
  project     = var.project_id
  
  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.environment}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.backend_service.id
}

resource "google_compute_health_check" "health_check" {
  name               = "${var.environment}-health-check"
  project            = var.project_id
  check_interval_sec = var.health_check_interval
  timeout_sec        = var.health_check_timeout
  
  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "${var.environment}-backend-service"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.health_check.id]
  load_balancing_scheme = "EXTERNAL"
  
  backend {
    group           = var.instance_group_1
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  
  dynamic "backend" {
    for_each = var.instance_group_2 != "" ? [1] : []
    content {
      group           = var.instance_group_2
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  }
  
  security_policy = var.security_policy != "" ? var.security_policy : null
  session_affinity = var.enable_session_affinity ? "CLIENT_IP" : "NONE"
  enable_cdn = var.enable_cdn
  
  dynamic "iap" {
    for_each = var.enable_iap ? [1] : []
    content {
      enabled              = var.enable_iap
      oauth2_client_id     = var.iap_oauth2_client_id
      oauth2_client_secret = var.iap_oauth2_client_secret
    }
  }
}