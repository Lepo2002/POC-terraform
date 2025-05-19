module "gcp_firewall" {
  source = "../../modules/gcp_networking/firewall/v1"
  
  project_id  = module.gcp_project.project_id
  network_id  = module.gcp_networking.vpc_id
  environment = local.environment
  
  common_rules = {
    "allow-health-checks" = {
      direction     = "INGRESS"
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
      target_tags  = ["http-server", "https-server"]
      description  = "Consente il traffico dagli health check di Google Cloud Load Balancer"
    },
    
    "allow-ssh" = {
      direction     = "INGRESS"
      source_ranges = ["0.0.0.0/0"]  
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
      target_tags  = ["ssh"]
      description  = "Consente il traffico SSH in entrata"
    }
  }
  
  environment_rules = {
    development = {
      "dev-allow-internal" = {
        direction     = "INGRESS"
        source_ranges = ["10.20.0.0/16"]  
        allow = [
          {
            protocol = "tcp"
            ports    = ["0-65535"]
          },
          {
            protocol = "udp"
            ports    = ["0-65535"]
          },
          {
            protocol = "icmp"
            ports    = []
          }
        ]
        target_tags  = ["internal"]
        description  = "Consente tutto il traffico interno tra risorse di sviluppo"
      },
      
      "dev-allow-lb-traffic" = {
        direction     = "INGRESS"
        source_ranges = ["0.0.0.0/0"]
        allow = [
          {
            protocol = "tcp"
            ports    = ["80", "443"]
          }
        ]
        target_tags  = ["http-server", "https-server"]
        description  = "Consente il traffico HTTP/HTTPS in entrata per i load balancer di sviluppo"
      },
      
      "dev-allow-debug" = {
        direction     = "INGRESS"
        source_ranges = ["0.0.0.0/0"] 
        allow = [
          {
            protocol = "tcp"
            ports    = ["8080", "9090", "3000", "5000"]  
          }
        ]
        target_tags  = ["dev-server"]
        description  = "Consente l'accesso a porte di debug/sviluppo (solo ambiente development)"
      }
    },
    
    production = {},  
    testing = {}     
  }
}