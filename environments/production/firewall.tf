module "azure_network_security" {
  source = "../../modules/azure_networking/firewall/v1"

  resource_group_name = module.azure_core.resource_group_name
  vnet_name           = module.azure_networking.vnet_name
  environment         = local.environment

  network_security_groups = [
    { name = "${local.prefix}-app-nsg" },
    { name = "${local.prefix}-data-nsg" },
    { name = "${local.prefix}-k8s-nsg" }
  ]

  security_rules = [

    {
      name                       = "allow-internal-traffic"
      nsg_name                   = "${local.prefix}-app-nsg"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "allow-lb-traffic"
      nsg_name                   = "${local.prefix}-app-nsg"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "restrict-external-access"
      nsg_name                   = "${local.prefix}-app-nsg"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "VirtualNetwork"
    },
    
    {
      name                       = "allow-app-to-data"
      nsg_name                   = "${local.prefix}-data-nsg"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433,3306,5432,6379,27017"
      source_address_prefix      = local.network_config.azure.primary.app_subnet_cidr
      destination_address_prefix = local.network_config.azure.primary.data_subnet_cidr
    },
    {
      name                       = "deny-all-other-inbound"
      nsg_name                   = "${local.prefix}-data-nsg"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    
    {
      name                       = "allow-api-server"
      nsg_name                   = "${local.prefix}-k8s-nsg"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "AzureCloud"
      destination_address_prefix = local.network_config.azure.primary.k8s_subnet_cidr
    },
    {
      name                       = "allow-internal-k8s-traffic"
      nsg_name                   = "${local.prefix}-k8s-nsg"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = local.network_config.azure.primary.k8s_subnet_cidr
      destination_address_prefix = local.network_config.azure.primary.k8s_subnet_cidr
    },
    {
      name                       = "allow-load-balancer"
      nsg_name                   = "${local.prefix}-k8s-nsg"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      name                       = "deny-all-other-inbound-k8s"
      nsg_name                   = "${local.prefix}-k8s-nsg"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  subnet_nsg_associations = [
    {
      subnet_name = "${local.prefix}-app-subnet"
      nsg_name    = "${local.prefix}-app-nsg"
    },
    {
      subnet_name = "${local.prefix}-data-subnet"
      nsg_name    = "${local.prefix}-data-nsg"
    },
    {
      subnet_name = "${local.prefix}-k8s-subnet"
      nsg_name    = "${local.prefix}-k8s-nsg"
    }
  ]
}

# Azure Firewall
module "azure_firewall" {
  source = "../../modules/azure_firewall/v1"

  firewall_name         = "${local.environment}-firewall"
  location             = var.azure_location
  resource_group_name  = module.azure_core.resource_group_name
  subnet_id            = module.azure_networking.firewall_subnet_id
  public_ip_address_id = module.azure_networking.firewall_public_ip_id
  environment         = local.environment

  # Configurare le regole specifiche qui
}

# GCP Firewall
module "gcp_firewall" {
  source = "../../modules/gcp_firewall/v1"

  project_id   = var.gcp_project_id
  vpc_network = module.gcp_networking.vpc_network_name

  firewall_rules = {
    "allow-internal" = {
      description = "Allows internal communication"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["10.0.0.0/8"]
      allow = [{
        protocol = "tcp"
        ports    = ["0-65535"]
      }]
    }
    "allow-health-check" = {
      description = "Allows health checks"
      direction   = "INGRESS"
      priority    = 1000
      source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
      allow = [{
        protocol = "tcp"
      }]
    }
  }
}

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
    
    "allow-internal-ssh" = {
      direction     = "INGRESS"
      source_ranges = [local.network_config.gcp.primary.vpc_cidr]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
      target_tags  = ["ssh"]
      description  = "Consente il traffico SSH solo dalla rete interna"
    },
    
    "allow-iap-ssh" = {
      direction     = "INGRESS"
      source_ranges = ["35.235.240.0/20"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "3389"]
        }
      ]
      target_tags  = ["ssh"]
      description  = "Consente il traffico SSH tramite IAP"
    }
  }
  
  environment_rules = {
    production = {
      "prod-allow-internal" = {
        direction     = "INGRESS"
        source_ranges = [local.network_config.gcp.primary.vpc_cidr]
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
        description  = "Consente tutto il traffico interno tra risorse di produzione"
      },
      
      "prod-allow-lb-traffic" = {
        direction     = "INGRESS"
        source_ranges = ["0.0.0.0/0"]
        allow = [
          {
            protocol = "tcp"
            ports    = ["80", "443"]
          }
        ]
        target_tags  = ["http-server", "https-server"]
        description  = "Consente il traffico HTTP/HTTPS in entrata per i load balancer di produzione"
      },
      
      "prod-deny-all-ingress" = {
        direction     = "INGRESS"
        source_ranges = ["0.0.0.0/0"]
        allow         = []
        target_tags   = []
        description   = "Nega tutto il traffico in ingresso non esplicitamente consentito"
      }
    },
    
    development = {},
    testing = {}
  }
}