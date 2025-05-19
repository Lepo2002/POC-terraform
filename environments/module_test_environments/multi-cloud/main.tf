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
  vpc_name           = "${local.prefix}-interconnect-vpc-test"
  region             = var.gcp_region
  routing_mode       = "GLOBAL"

  subnets = [
    {
      name   = "${local.prefix}-interconnect-subnet-test"
      region = var.gcp_region
      cidr   = "10.100.40.0/24"
      secondary_ranges = []
    }
  ]
}

resource "google_compute_router" "test_router" {
  name    = "${local.prefix}-router-test"
  project = var.gcp_project_id
  region  = var.gcp_region
  network = module.gcp_networking_test.vpc_id
  
  bgp {
    asn = 65000
  }
}

resource "azurerm_resource_group" "test_rg" {
  name     = "${local.prefix}-interconnect-test-rg"
  location = var.azure_region
  tags     = local.common_tags
}

module "azure_networking_test" {
  source = "../../../modules/azure_networking/v1"

  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  environment         = local.environment

  vnet_name     = "${local.prefix}-interconnect-vnet-test"
  address_space = ["10.50.40.0/24"]

  subnets = [
    {
      name             = "${local.prefix}-interconnect-subnet-test"
      address_prefix   = "10.50.40.0/27"
      service_endpoints = []
    },
    {
      name             = "GatewaySubnet" 
      address_prefix   = "10.50.40.32/27"
      service_endpoints = []
    }
  ]
  
  tags = local.common_tags
}

resource "azurerm_public_ip" "test_gateway_ip" {
  name                = "${local.prefix}-vpn-ip-test"
  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  allocation_method   = "Dynamic"
  
  tags = local.common_tags
}

module "multi_cloud_interconnect_test" {
  source = "../../../modules/multi_cloud/interconnect/v1"

  environment        = local.environment
  gcp_project_id     = var.gcp_project_id
  gcp_region         = var.gcp_region
  gcp_network_id     = module.gcp_networking_test.vpc_id
  gcp_router_id      = google_compute_router.test_router.id

  azure_resource_group_name = azurerm_resource_group.test_rg.name
  azure_location            = var.azure_region

  interconnect_name  = "${local.prefix}-interconnect-test"
  express_route_name = "${local.prefix}-expressroute-test"
  azure_peering_location = "Amsterdam"
  azure_bandwidth_mbps   = 50

  create_gcp_vpn_backup  = true
  create_azure_vpn_backup = true
  vpn_shared_secret      = var.vpn_shared_secret
  azure_vpn_public_ip_id = azurerm_public_ip.test_gateway_ip.id
  azure_gateway_subnet_id = module.azure_networking_test.subnet_ids["GatewaySubnet"]
  
  azure_vpn_ip_1 = "1.2.3.4"
  azure_vpn_ip_2 = "1.2.3.5"
}

module "multi_cloud_identity_federation_test" {
  source = "../../../modules/multi_cloud/federated_identity/v1"
  
  environment = local.environment
  gcp_project_id = var.gcp_project_id
  gcp_project_number = var.gcp_project_number
  
  create_gcp_identity_pool = true
  identity_pool_name = "${local.prefix}-test-identity-pool"
  federated_sa_name = "${local.prefix}-test-federated-sa"
  
  create_azure_app = true
  azure_tenant_id = var.azure_tenant_id

  gcp_sa_roles = [
    "roles/storage.objectViewer",
    "roles/pubsub.viewer"
  ]
  
  create_azure_managed_identity = true
  azure_resource_group_name = azurerm_resource_group.test_rg.name
  azure_location = var.azure_region
  azure_identity_name = "${local.prefix}-test-federated-identity"
  
  azure_identity_roles = [
    "Reader"
  ]
  azure_subscription_id = var.azure_subscription_id
}

output "interconnect_test_gcp_id" {
  description = "ID of the test GCP interconnect attachment"
  value       = module.multi_cloud_interconnect_test.gcp_interconnect_id
}

output "interconnect_test_gcp_pairing_key" {
  description = "Pairing key of the test GCP interconnect"
  value       = module.multi_cloud_interconnect_test.gcp_interconnect_pairing_key
}

output "interconnect_test_azure_express_route_id" {
  description = "ID of the test Azure ExpressRoute circuit"
  value       = module.multi_cloud_interconnect_test.azure_express_route_id
}

output "interconnect_test_gcp_vpn_gateway_id" {
  description = "ID of the test GCP VPN gateway"
  value       = module.multi_cloud_interconnect_test.gcp_vpn_gateway_id
}

output "interconnect_test_azure_vpn_gateway_id" {
  description = "ID of the test Azure VPN gateway"
  value       = module.multi_cloud_interconnect_test.azure_vpn_gateway_id
}

output "federation_test_gcp_identity_pool_id" {
  description = "ID of the test GCP identity pool"
  value       = module.multi_cloud_identity_federation_test.gcp_identity_pool_id
}

output "federation_test_azure_app_id" {
  description = "ID of the test Azure AD application"
  value       = module.multi_cloud_identity_federation_test.azure_app_id
}

output "federation_test_azure_managed_identity_id" {
  description = "ID of the test Azure managed identity"
  value       = module.multi_cloud_identity_federation_test.azure_managed_identity_id
}