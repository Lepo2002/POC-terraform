provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = false
    }
  }

  skip_provider_registration = true
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "azuread" {}