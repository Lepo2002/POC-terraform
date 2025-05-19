
# Regole comuni per GCP Firewall

locals {
  common_firewall_rules = {
    "allow-internal" = {
      description   = "Allows internal communication"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["10.0.0.0/8"]
      allow = [{
        protocol = "all"
      }]
    }
    "allow-health-checks" = {
      description   = "Allows health check access"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow = [{
        protocol = "tcp"
      }]
    }
  }
}
