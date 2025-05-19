provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

locals {
  environment = "module-test"
  prefix      = "modtest"
  common_tags = {
    environment = "module-test"
    managed_by  = "terraform"
    purpose     = "module-testing"
  }
}

module "gcp_iam_test" {
  source = "../../../modules/gcp_iam/v1"

  project_id           = var.gcp_project_id
  environment          = local.environment
  service_account_name = "${local.prefix}-test-sa"
  
  service_account_roles = [
    "roles/compute.viewer",
    "roles/storage.objectViewer"
  ]
  
  create_service_account_key = true
  
  custom_role_definitions = {
    "testReadOnlyRole" = {
      title       = "Test Read Only Role"
      description = "Custom role for testing module functionality"
      permissions = [
        "compute.instances.get",
        "compute.instances.list"
      ]
      stage = "ALPHA" 
    }
  }
  
  enable_audit_logging = true
  audit_services = {
    "allServices" = {
      "DATA_READ"  = ["serviceAccount:${local.prefix}-test-sa@${var.gcp_project_id}.iam.gserviceaccount.com"]
      "DATA_WRITE" = []
      "ADMIN_READ" = []
    }
  }
}

resource "google_storage_bucket" "test_bucket" {
  name          = "${var.gcp_project_id}-test-bucket"
  location      = var.gcp_region
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "test_binding" {
  bucket  = google_storage_bucket.test_bucket.name
  role    = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${module.gcp_iam_test.service_account_email}"
  ]
}

resource "azurerm_resource_group" "test_rg" {
  name     = "${local.prefix}-iam-test-rg"
  location = var.azure_region
  tags     = local.common_tags
}

module "azure_identity_test" {
  source = "../../../modules/azure_identity/v1"

  resource_group_name = azurerm_resource_group.test_rg.name
  location            = var.azure_region
  environment         = local.environment

  user_assigned_identities = [
    {
      name = "${local.prefix}-test-identity"
    }
  ]
  
  identity_role_assignments = [
    {
      identity_name        = "${local.prefix}-test-identity"
      scope                = azurerm_resource_group.test_rg.id
      role_definition_name = "Reader"
    }
  ]
  
  azure_ad_applications = [
    {
      display_name    = "${local.prefix}-test-app"
      identifier_uris = ["api://test-app-${local.prefix}"]
      create_password = true
      password_end_date_relative = "8760h" 
      redirect_uris = ["https://localhost/auth"]
      oauth2_permission_scopes = [
        {
          id                         = "00000000-0000-0000-0000-000000000001"
          admin_consent_description  = "Test scope description"
          admin_consent_display_name = "Test scope"
        }
      ]
    }
  ]
  
  azure_ad_groups = [
    {
      display_name     = "${local.prefix}-test-group"
      security_enabled = true
      description      = "Test group for IAM module testing"
    }
  ]
  
  custom_roles = [
    {
      name              = "TestCustomRole"
      scope             = azurerm_resource_group.test_rg.id
      description       = "Custom role for testing"
      actions           = ["Microsoft.Resources/subscriptions/resourceGroups/read"]
      assignable_scopes = [azurerm_resource_group.test_rg.id]
    }
  ]
  
  tags = local.common_tags
}

module "multi_cloud_identity_federation_test" {
  source = "../../../modules/multi_cloud/federated_identity/v1"
  
  environment = local.environment
  gcp_project_id = var.gcp_project_id
  gcp_project_number = var.gcp_project_number
  
  create_gcp_identity_pool = true
  identity_pool_name = "${local.prefix}-test-pool"
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
  azure_identity_name = "${local.prefix}-test-gcp-identity"
  
  azure_identity_roles = [
    "Reader"
  ]
}

output "gcp_service_account_email" {
  description = "Email of the test service account in GCP"
  value       = module.gcp_iam_test.service_account_email
}

output "gcp_service_account_id" {
  description = "ID of the test service account in GCP"
  value       = module.gcp_iam_test.service_account_id
}

output "gcp_custom_roles_created" {
  description = "Custom roles created in GCP"
  value       = module.gcp_iam_test.custom_roles_created
}

output "azure_identity_ids" {
  description = "IDs of the test identities in Azure"
  value       = module.azure_identity_test.user_assigned_identity_ids
}

output "azure_application_ids" {
  description = "IDs of the test applications in Azure AD"
  value       = module.azure_identity_test.application_ids
}

output "azure_group_ids" {
  description = "IDs of the test groups in Azure AD"
  value       = module.azure_identity_test.group_ids
}

output "azure_custom_role_ids" {
  description = "IDs of the custom roles in Azure"
  value       = module.azure_identity_test.custom_role_ids
}

output "multi_cloud_identity_pool_id" {
  description = "ID of the GCP identity pool for federation testing"
  value       = module.multi_cloud_identity_federation_test.gcp_identity_pool_id
}

output "multi_cloud_azure_managed_identity_id" {
  description = "ID of the Azure managed identity for federation testing"
  value       = module.multi_cloud_identity_federation_test.azure_managed_identity_id
}