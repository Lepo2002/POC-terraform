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

resource "random_id" "storage_suffix" {
  byte_length = 4
}

resource "azurerm_resource_group" "test_rg" {
  name     = "${local.prefix}-storage-test-rg"
  location = var.azure_region
  tags     = local.common_tags
}

module "azure_networking_test" {
  source = "../../../modules/azure_networking/v1"

  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  environment         = local.environment

  vnet_name     = "${local.prefix}-storage-vnet-test"
  address_space = ["10.50.0.0/16"]

  subnets = [
    {
      name             = "${local.prefix}-storage-subnet-test"
      address_prefix   = "10.50.30.0/24"
      service_endpoints = ["Microsoft.Storage"]
    }
  ]
  
  tags = local.common_tags
}

module "azure_storage_test" {
  source = "../../../modules/azure_storage/v1"
  
  environment = local.environment
  resource_group_name = azurerm_resource_group.test_rg.name
  location = var.azure_region
  storage_account_name = "modteststorage${random_id.storage_suffix.hex}"
  
  account_tier = "Standard"
  replication_type = "LRS"
  access_tier = "Hot"
  
  enable_https_traffic_only = true
  min_tls_version = "TLS1_2"
  allow_public_access = false
  
  enable_blob_versioning = true
  enable_change_feed = true
  blob_soft_delete_retention_days = 7
  container_soft_delete_retention_days = 7
  
  network_default_action = "Deny"
  subnet_ids = [
    module.azure_networking_test.subnet_ids["${local.prefix}-storage-subnet-test"]
  ]
  
  containers = [
    {
      name = "test-data"
      access_type = "private"
    },
    {
      name = "test-public"
      access_type = "blob"
    }
  ]

  file_shares = [
    {
      name = "test-share"
      quota = 5
      access_tier = "TransactionOptimized"
      permissions = "rwdl"
      start_date = "2023-01-01T00:00:00Z"
      expiry_date = "2025-01-01T00:00:00Z"
    }
  ]
  
  tables = ["testtable1", "testtable2"]
  queues = ["testqueue1", "testqueue2"]
  
  lifecycle_rules = [
    {
      name = "test-lifecycle"
      prefix_match = ["test-data/"]
      blob_types = ["blockBlob"]
      base_blob = {
        tier_to_cool_after_days = 30
        tier_to_archive_after_days = 90
        delete_after_days = 365
      }
      snapshot = {
        delete_after_days = 30
      }
      version = {
        delete_after_days = 90
      }
    }
  ]

  enable_private_endpoint = true
  private_endpoint_subnet_id = module.azure_networking_test.subnet_ids["${local.prefix}-storage-subnet-test"]
  
  tags = local.common_tags
}

resource "google_storage_bucket" "test_bucket_standard" {
  name          = "${var.gcp_project_id}-test-standard-${random_id.storage_suffix.hex}"
  location      = var.gcp_region
  storage_class = "STANDARD"
  force_destroy = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
  
  labels = {
    environment = local.environment
    purpose     = "module-testing"
  }
}

resource "google_storage_bucket" "test_bucket_regional" {
  name          = "${var.gcp_project_id}-test-regional-${random_id.storage_suffix.hex}"
  location      = var.gcp_region
  storage_class = "REGIONAL"
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  cors {
    origin          = ["http://example.com"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  labels = {
    environment = local.environment
    purpose     = "module-testing"
  }
}

resource "google_storage_bucket_iam_binding" "test_binding" {
  bucket = google_storage_bucket.test_bucket_standard.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}

resource "google_storage_bucket_object" "test_object" {
  name    = "test-object"
  bucket  = google_storage_bucket.test_bucket_standard.name
  content = "This is a test object for module testing."
}

output "azure_storage_account_name" {
  description = "Name of the test storage account"
  value       = module.azure_storage_test.storage_account_name
}

output "azure_storage_account_id" {
  description = "ID of the test storage account"
  value       = module.azure_storage_test.storage_account_id
}

output "azure_blob_endpoint" {
  description = "Blob endpoint of the test storage account"
  value       = module.azure_storage_test.primary_blob_endpoint
}

output "azure_container_ids" {
  description = "IDs of the test containers"
  value       = module.azure_storage_test.container_ids
}

output "gcp_standard_bucket_name" {
  description = "Name of the standard test bucket"
  value       = google_storage_bucket.test_bucket_standard.name
}

output "gcp_regional_bucket_name" {
  description = "Name of the regional test bucket"
  value       = google_storage_bucket.test_bucket_regional.name
}

output "gcp_bucket_urls" {
  description = "URLs of the test buckets"
  value = {
    standard = google_storage_bucket.test_bucket_standard.url
    regional = google_storage_bucket.test_bucket_regional.url
  }
}