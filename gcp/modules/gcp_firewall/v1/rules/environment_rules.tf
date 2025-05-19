
# Regole specifiche per ambiente GCP Firewall

locals {
  environment_firewall_rules = {
    production = {
      "prod-allow-lb" = {
        description   = "Allow load balancer traffic"
        direction     = "INGRESS"
        priority      = 1000
        source_ranges = ["0.0.0.0/0"]
        target_tags   = ["http-server", "https-server"]
        allow = [{
          protocol = "tcp"
          ports    = ["80", "443"]
        }]
      }
    }
    development = {
      "dev-allow-ssh" = {
        description   = "Allow SSH access"
        direction     = "INGRESS"
        priority      = 1000
        source_ranges = ["0.0.0.0/0"]
        target_tags   = ["ssh"]
        allow = [{
          protocol = "tcp"
          ports    = ["22"]
        }]
      }
    }
  }
}
