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

resource "google_service_account" "gke_test_sa" {
  account_id   = "${local.prefix}-gke-test-sa"
  display_name = "Service Account for GKE module testing"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "gke_test_sa_roles" {
  for_each = toset([
    "roles/container.admin",
    "roles/compute.admin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])
  
  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_test_sa.email}"
}

module "gcp_networking_test" {
  source = "../../../modules/gcp_networking/v1"

  project_id         = var.gcp_project_id
  vpc_name           = "${local.prefix}-k8s-vpc-test"
  region             = var.gcp_region
  create_nat_gateway = true

  subnets = [
    {
      name   = "${local.prefix}-k8s-subnet-test"
      region = var.gcp_region
      cidr   = "10.100.10.0/24"
      secondary_ranges = [
        { name = "pod-range-test", cidr = "10.200.0.0/20" },
        { name = "svc-range-test", cidr = "10.201.0.0/22" }
      ]
    }
  ]
}

resource "azurerm_resource_group" "test_rg" {
  name     = "${local.prefix}-k8s-test-rg"
  location = var.azure_region
  tags     = local.common_tags
}

module "azure_networking_test" {
  source = "../../../modules/azure_networking/v1"

  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  environment         = local.environment

  vnet_name     = "${local.prefix}-k8s-vnet-test"
  address_space = ["10.50.0.0/16"]

  subnets = [
    {
      name             = "${local.prefix}-k8s-subnet-test"
      address_prefix   = "10.50.10.0/24"
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
  ]
  
  tags = local.common_tags
}

module "gcp_kubernetes_test" {
  source = "../../../modules/gcp_kubernates/v1"

  project_id          = var.gcp_project_id
  cluster_name        = "${local.prefix}-gke-test"
  region              = var.gcp_region
  zone                = "${var.gcp_region}-b"
  environment         = local.environment
  regional_cluster    = false  

  kubernetes_version  = var.kubernetes_version
  node_count          = 1      
  node_machine_type   = "e2-standard-2"

  network_id          = module.gcp_networking_test.vpc_id
  subnetwork_id       = module.gcp_networking_test.subnet_ids["${local.prefix}-k8s-subnet-test"]
  cluster_secondary_range_name = "pod-range-test"
  services_secondary_range_name = "svc-range-test"

  private_cluster     = true
  private_endpoint    = true
  master_ipv4_cidr_block = "172.16.0.0/28"

  service_account_email = google_service_account.gke_test_sa.email
  
  enable_dr           = true
  dr_location         = "${var.gcp_region}-c"  
  dr_node_count       = 1
}

module "azure_kubernetes_test" {
  source = "../../../modules/azure_kubernetes/v1"  

  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  environment         = local.environment

  cluster_name       = "${local.prefix}-aks-test"
  kubernetes_version = var.kubernetes_version
  node_count         = 1      
  node_vm_size       = "Standard_D2s_v3"

  network_plugin     = "azure"
  network_policy     = "calico"
  vnet_subnet_id     = module.azure_networking_test.subnet_ids["${local.prefix}-k8s-subnet-test"]

  enable_auto_scaling = true
  min_node_count     = 1
  max_node_count     = 3
  
  tags = local.common_tags
}

output "gcp_kubernetes_cluster_name" {
  description = "Name of the test GKE cluster"
  value       = module.gcp_kubernetes_test.cluster_name
}

output "gcp_kubernetes_cluster_id" {
  description = "ID of the test GKE cluster"
  value       = module.gcp_kubernetes_test.cluster_id
}

output "gcp_kubernetes_endpoint" {
  description = "Endpoint of the test GKE cluster"
  value       = module.gcp_kubernetes_test.cluster_endpoint
  sensitive   = true
}

output "gcp_kubernetes_dr_cluster_name" {
  description = "Name of the test GKE DR cluster"
  value       = module.gcp_kubernetes_test.dr_cluster_name
}

output "azure_kubernetes_cluster_name" {
  description = "Name of the test AKS cluster" 
  value       = module.azure_kubernetes_test.cluster_name
}

output "azure_kubernetes_id" {
  description = "ID of the test AKS cluster"
  value       = module.azure_kubernetes_test.cluster_id
}

output "gcp_command_line" {
  description = "Command to get credentials for GKE test cluster"
  value       = module.gcp_kubernetes_test.gke_command_line
}