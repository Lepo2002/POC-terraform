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
  vpc_name           = "${local.prefix}-db-vpc-test"
  region             = var.gcp_region
  create_nat_gateway = true
  create_private_service_access = true

  subnets = [
    {
      name   = "${local.prefix}-db-subnet-test"
      region = var.gcp_region
      cidr   = "10.100.20.0/24"
      secondary_ranges = []
    }
  ]
}

resource "azurerm_resource_group" "test_rg" {
  name     = "${local.prefix}-db-test-rg"
  location = var.azure_region
  tags     = local.common_tags
}

module "azure_networking_test" {
  source = "../../../modules/azure_networking/v1"

  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  environment         = local.environment

  vnet_name     = "${local.prefix}-db-vnet-test"
  address_space = ["10.50.0.0/16"]

  subnets = [
    {
      name             = "${local.prefix}-db-subnet-test"
      address_prefix   = "10.50.20.0/24"
      service_endpoints = ["Microsoft.Sql"]
    }
  ]
  
  tags = local.common_tags
}

module "gcp_database_test" {
  source = "../../../modules/gcp_database/v1"

  project_id      = var.gcp_project_id
  environment     = local.environment
  region          = var.gcp_region

  instance_name   = "${local.prefix}-db-test"
  database_name   = "${local.prefix}-main-db-test"
  database_version = "POSTGRES_13"
  database_tier   = "db-f1-micro" 

  availability_type = "ZONAL" 
  backup_enabled    = true
  backup_start_time = "02:00"
  
  network_id        = module.gcp_networking_test.vpc_id
  private_network   = true

  database_username = var.database_admin_username
  database_password = var.database_admin_password
  
  additional_users = {
    "test_readonly" = var.database_readonly_password
    "test_admin" = var.database_admin_password
  }
  
  additional_database_flags = {
    "log_statement" = "all"
    "log_min_duration_statement" = "1000"
  }
}

module "azure_database_test" {
  source = "../../../modules/azure_database/v1"

  resource_group_name  = azurerm_resource_group.test_rg.name
  region               = var.azure_region
  environment          = local.environment

  instance_name       = "${local.prefix}-sqlserver-test"
  database_name       = "${local.prefix}-main-db-test"
  database_username   = var.database_admin_username
  database_password   = var.database_admin_password

  private_network     = true
  private_subnet_id   = module.azure_networking_test.subnet_ids["${local.prefix}-db-subnet-test"]

  database_tier       = "Basic"  
  backup_enabled      = true

  authorized_networks = {
    "test-network" = {
      start_ip = "10.0.0.1"
      end_ip   = "10.0.0.255"
    }
  }
}

output "gcp_database_instance_name" {
  description = "Name of the test Cloud SQL instance"
  value       = module.gcp_database_test.instance_name
}

output "gcp_database_instance_id" {
  description = "ID of the test Cloud SQL instance"
  value       = module.gcp_database_test.instance_id
}

output "gcp_database_connection_name" {
  description = "Connection name of the test Cloud SQL instance"
  value       = module.gcp_database_test.connection_name
}

output "azure_database_instance_name" {
  description = "Name of the test Azure SQL instance"
  value       = module.azure_database_test.instance_name
}

output "azure_database_connection_string" {
  description = "Connection string of the test Azure SQL database"
  value       = module.azure_database_test.connection_string
  sensitive   = true
}