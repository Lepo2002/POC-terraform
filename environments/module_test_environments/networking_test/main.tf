provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "azurerm" {
  features {}
}

locals {
  environment = "module-test"
  prefix      = "modtest"
  common_tags = {
    environment = "module-test"
    managed_by  = "terraform"
    purpose     = "module-testing"
  }
}

module "gcp_networking_test" {
  source = "../../../modules/gcp_networking/v1"

  project_id         = var.gcp_project_id
  vpc_name           = "${local.prefix}-vpc-test"
  region             = var.gcp_region
  create_nat_gateway = true

  subnets = [
    {
      name   = "${local.prefix}-app-subnet"
      region = var.gcp_region
      cidr   = "10.100.0.0/24"
      secondary_ranges = [
        { name = "pod-range-test", cidr = "10.200.0.0/22" },
        { name = "svc-range-test", cidr = "10.201.0.0/24" }
      ]
    },
    {
      name   = "${local.prefix}-data-subnet"
      region = var.gcp_region
      cidr   = "10.100.1.0/24"
      secondary_ranges = []
    }
  ]
  
  routes = {
    "test-route" = {
      destination_range = "192.168.0.0/24"
      priority          = 1000
      next_hop_type     = "gateway"
      next_hop_target   = "default-internet-gateway"
      next_hop_zone     = ""
    }
  }
}

module "gcp_firewall_test" {
  source = "../../../modules/gcp_monitoring/v1"
  
  project_id  = var.gcp_project_id
  network_id  = module.gcp_networking_test.vpc_id
  environment = local.environment
  
  common_rules = {
    "allow-test-internal" = {
      direction     = "INGRESS"
      source_ranges = ["10.100.0.0/16"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        }
      ]
      target_tags  = ["test-internal"]
      description  = "Allow internal traffic for testing"
    }
  }
  
  environment_rules = {
    development = {
      "dev-rule-test" = {
        direction     = "INGRESS"
        source_ranges = ["0.0.0.0/0"]
        allow = [
          {
            protocol = "tcp"
            ports    = ["80", "443"]
          }
        ]
        target_tags  = ["http-server"]
        description  = "Test rule for HTTP traffic"
      }
    },
    testing = {},
    production = {}
  }
}

resource "azurerm_resource_group" "test_rg" {
  name     = "${local.prefix}-networking-test-rg"
  location = var.azure_region
  tags     = local.common_tags
}

module "azure_networking_test" {
  source = "../../../modules/azure_networking/v1"

  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  environment         = local.environment

  vnet_name     = "${local.prefix}-vnet-test"
  address_space = ["10.50.0.0/16"]

  subnets = [
    {
      name             = "${local.prefix}-app-subnet-test"
      address_prefix   = "10.50.1.0/24"
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "${local.prefix}-data-subnet-test"
      address_prefix   = "10.50.2.0/24"
      service_endpoints = ["Microsoft.Sql"]
    }
  ]

  network_security_groups = [
    { name = "${local.prefix}-app-nsg-test" },
    { name = "${local.prefix}-data-nsg-test" }
  ]

  security_rules = [
    {
      name                       = "allow-internal-traffic-test"
      nsg_name                   = "${local.prefix}-app-nsg-test"
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
      name                       = "allow-http-test"
      nsg_name                   = "${local.prefix}-app-nsg-test"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  subnet_nsg_associations = [
    {
      subnet_name = "${local.prefix}-app-subnet-test"
      nsg_name    = "${local.prefix}-app-nsg-test"
    },
    {
      subnet_name = "${local.prefix}-data-subnet-test"
      nsg_name    = "${local.prefix}-data-nsg-test"
    }
  ]
  
  tags = local.common_tags
}

resource "azurerm_route_table" "test_route_table" {
  name                = "${local.prefix}-route-table-test"
  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  
  route {
    name                   = "test-route"
    address_prefix         = "192.168.0.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.50.1.4"
  }
  
  tags = local.common_tags
}

resource "azurerm_subnet_route_table_association" "test_association" {
  subnet_id      = module.azure_networking_test.subnet_ids["${local.prefix}-app-subnet-test"]
  route_table_id = azurerm_route_table.test_route_table.id
}

output "gcp_vpc_id" {
  description = "ID of the test VPC in GCP"
  value       = module.gcp_networking_test.vpc_id
}

output "gcp_subnet_ids" {
  description = "IDs of the test subnets in GCP"
  value       = module.gcp_networking_test.subnet_ids
}

output "gcp_firewall_rules" {
  description = "Created firewall rules in GCP"
  value       = module.gcp_firewall_test.common_firewall_rules
}

output "azure_vnet_id" {
  description = "ID of the test VNet in Azure"
  value       = module.azure_networking_test.vnet_id
}

output "azure_subnet_ids" {
  description = "IDs of the test subnets in Azure"
  value       = module.azure_networking_test.subnet_ids
}

output "azure_nsg_ids" {
  description = "IDs of the test NSGs in Azure"
  value       = module.azure_networking_test.nsg_ids
}