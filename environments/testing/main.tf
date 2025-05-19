provider "azurerm" {
  features {}
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

locals {
  environment = "testing"
  common_tags = {
    environment = "testing"
    managed_by  = "terraform"
    project     = var.project_name
  }
}

module "azure_core" {
  source = "../../modules/azure_core/v1"

  resource_group_name = "dev-${var.project_name}-rg"
  location            = var.azure_region
  environment         = local.environment

  additional_tags = local.common_tags

  role_assignments = {
    "dev_admin" = {
      role         = "Contributor"
      principal_id = var.azure_platform_admin_id
    }
  }
}

module "gcp_project" {
  source = "../../modules/gcp_project/v1"

  project_name        = "dev-${var.project_name}"
  project_id          = var.gcp_project_id
  organization_id     = var.gcp_organization_id
  billing_account     = var.gcp_billing_account
  folder_name         = "dev-INFRA"
  environment         = local.environment
}

module "azure_networking" {
  source = "../../modules/azure_networking/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  vnet_name       = "dev-${var.project_name}-vnet"
  address_space   = ["10.20.0.0/16"]

  subnets = [
    {
      name             = "dev-app-subnet"
      address_prefix   = "10.20.1.0/24"
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    },
    {
      name             = "dev-data-subnet"
      address_prefix   = "10.20.2.0/24"
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
  ]
}

module "gcp_networking" {
  source = "../../modules/gcp_networking/v1"

  project_id         = module.gcp_project.project_id
  vpc_name           = "dev-${var.project_name}-vpc"
  region             = var.gcp_region
  create_nat_gateway = true

  subnets = [
    {
      name   = "dev-app-subnet"
      region = var.gcp_region
      cidr   = "10.20.0.0/22"
      secondary_ranges = [
        { name = "pod-range", cidr = "10.200.0.0/16" },
        { name = "svc-range", cidr = "10.201.0.0/16" }
      ]
    }
  ]
}

module "azure_database" {
  source = "../../modules/azure_database/v1"

  resource_group_name  = module.azure_core.resource_group_name
  location             = var.azure_region
  environment          = local.environment

  instance_name       = "dev-${var.project_name}-sqlserver"
  database_name       = "dev-main-database"
  database_username   = var.database_admin_username
  database_password   = var.database_admin_password

  private_network     = true
  private_subnet_id   = module.azure_networking.subnet_ids["dev-data-subnet"]

  database_tier       = "Basic"
  backup_enabled      = true
}

module "gcp_database" {
  source = "../../modules/gcp_database/v1"

  project_id      = module.gcp_project.project_id
  environment     = local.environment
  region          = var.gcp_region

  instance_name   = "dev-${var.project_name}-db"
  database_name   = "dev-main-database"
  database_version = "POSTGRES_13"
  database_tier   = "db-f1-micro"

  availability_type = "ZONAL"
  backup_enabled    = true
  backup_start_time = "02:00"

  network_id        = module.gcp_networking.vpc_id
  private_network   = true

  database_username = var.database_admin_username
  database_password = var.database_admin_password
}

module "azure_kubernetes" {
  source = "../../modules/azure_kubernetes/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  cluster_name       = "dev-${var.project_name}-aks"
  kubernetes_version = "1.27"
  node_count         = 2
  node_vm_size       = "Standard_D2s_v3"

  network_plugin     = "azure"
  network_policy     = "calico"
  vnet_subnet_id     = module.azure_networking.subnet_ids["dev-app-subnet"]
}

module "gcp_kubernetes" {
  source = "../../modules/gcp_kubernetes/v1"

  project_id          = module.gcp_project.project_id
  cluster_name        = "dev-${var.project_name}-gke"
  region              = var.gcp_region
  zone                = "${var.gcp_region}-b"
  environment         = local.environment

  kubernetes_version  = "1.27"
  node_count          = 2
  node_machine_type   = "e2-standard-2"

  network_id          = module.gcp_networking.vpc_id
  subnetwork_id       = module.gcp_networking.subnet_ids["dev-app-subnet"]

  private_cluster     = true
}

module "azure_ai" {
  source = "../../modules/azure_ai/v1"

  resource_group_name = module.azure_core.resource_group_name
  location            = var.azure_region
  environment         = local.environment

  account_name        = "dev-${var.project_name}-ai"
  account_kind        = "Cognitive"
  sku_name            = "F0"

  model_deployments = {
    "gpt-model" = {
      model_format   = "OpenAI"
      model_name     = "gpt-3.5-turbo"
      model_version  = "0613"
      scale_type     = "Standard"
      scale_capacity = 5
    }
  }
}