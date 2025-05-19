provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
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

resource "azurerm_resource_group" "test_rg" {
  name     = "${local.prefix}-security-test-rg"
  location = var.azure_region
  tags     = local.common_tags
}

module "gcp_security_test" {
  source = "../../../modules/gcp_security/v1"

  project_id = var.gcp_project_id
  environment = local.environment
  region     = var.gcp_region
  
  enable_kms = true
  crypto_keys = {
    "test-key-1" = {
      rotation_period  = "2592000s" 
      algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
      protection_level = "SOFTWARE"
    },
    "test-key-2" = {
      rotation_period  = "604800s"  
      algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
      protection_level = "SOFTWARE"
    }
  }
  
  secrets = {
    "test-secret-1" = {
      data = "This is a test secret for module testing"
      auto_replication = true
    },
    "test-secret-2" = {
      data = "Another test secret with different configuration"
      auto_replication = false
    }
  }
  
  secret_access_bindings = {
    "test-binding-1" = {
      secret_id = "test-secret-1"
      role      = "roles/secretmanager.secretAccessor"
      members   = ["serviceAccount:${var.gcp_service_account}"]
    }
  }
  
  enable_cloud_armor = true
  enable_ddos_protection = true
  
  cloud_armor_rules = [
    {
      action      = "deny(403)"
      priority    = 1000
      expression  = "evaluatePreconfiguredExpr('xss-stable')"
      description = "Test rule to prevent XSS attacks"
    },
    {
      action      = "allow"
      priority    = 2000
      expression  = "true"
      description = "Allow all other traffic"
    }
  ]
  
  enable_ssl_policy = true
  ssl_policy_profile = "RESTRICTED"
  ssl_min_tls_version = "TLS_1_2"
  
  enable_binary_authorization = true
  binary_auth_policy_mode = "GLOBAL"
  binary_auth_default_rule = "REQUIRE_ATTESTATION"
  binary_auth_enforce = false  
  binary_auth_whitelist_images = [
    "gcr.io/${var.gcp_project_id}/*"
  ]
  
  enable_network_security_policies = true
  network_security_policies = {
    "test-policy" = {
      description = "Test network security policy"
      rules = [
        {
          priority      = 1000
          description   = "Allow internal traffic"
          ip_protocol   = "all"
          ports         = []
          src_ip_ranges = ["10.0.0.0/8"]
          dest_ip_ranges = ["10.0.0.0/8"]
          action        = "allow"
        },
        {
          priority      = 2000
          description   = "Block specific external IPs"
          ip_protocol   = "tcp"
          ports         = ["80", "443"]
          src_ip_ranges = ["192.168.0.0/16"]
          dest_ip_ranges = ["0.0.0.0/0"]
          action        = "deny"
        }
      ]
    }
  }
}

resource "azurerm_key_vault" "test_key_vault" {
  name                        = "${local.prefix}-kv-${random_string.key_vault_suffix.result}"
  location                    = azurerm_resource_group.test_rg.location
  resource_group_name         = azurerm_resource_group.test_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.azure_tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  
  sku_name = "standard"
  
  tags = local.common_tags
}

resource "random_string" "key_vault_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_key_vault_access_policy" "test_policy" {
  key_vault_id = azurerm_key_vault.test_key_vault.id
  tenant_id    = var.azure_tenant_id
  object_id    = var.azure_object_id
  
  key_permissions = [
    "Get", "List", "Create", "Delete", "Update"
  ]
  
  secret_permissions = [
    "Get", "List", "Set", "Delete"
  ]
  
  certificate_permissions = [
    "Get", "List", "Create", "Delete"
  ]
}

resource "azurerm_key_vault_key" "test_key" {
  name         = "test-key"
  key_vault_id = azurerm_key_vault.test_key_vault.id
  key_type     = "RSA"
  key_size     = 2048
  
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "verify",
    "wrapKey",
    "unwrapKey"
  ]
  
  depends_on = [
    azurerm_key_vault_access_policy.test_policy
  ]
}

resource "azurerm_key_vault_secret" "test_secret" {
  name         = "test-secret"
  value        = "This is a test secret for Azure Key Vault"
  key_vault_id = azurerm_key_vault.test_key_vault.id
  
  depends_on = [
    azurerm_key_vault_access_policy.test_policy
  ]
}

resource "azurerm_security_center_subscription_pricing" "test_pricing" {
  tier          = "Standard"
  resource_type = "VirtualMachines"
}

resource "azurerm_security_center_contact" "test_contact" {
  name  = "test-contact"
  email = var.security_contact_email
  phone = var.security_contact_phone
  
  alert_notifications = true
  alerts_to_admins    = true
}

output "gcp_key_ring_name" {
  description = "Name of the test KMS key ring"
  value       = module.gcp_security_test.key_ring_name
}

output "gcp_crypto_key_ids" {
  description = "IDs of the test KMS crypto keys"
  value       = module.gcp_security_test.crypto_key_ids
}

output "gcp_secret_ids" {
  description = "IDs of the test secrets"
  value       = module.gcp_security_test.secret_ids
}

output "gcp_cloud_armor_policy_id" {
  description = "ID of the test Cloud Armor policy"
  value       = module.gcp_security_test.cloud_armor_policy_id
}

output "gcp_ssl_policy_id" {
  description = "ID of the test SSL policy"
  value       = module.gcp_security_test.ssl_policy_id
}

output "azure_key_vault_id" {
  description = "ID of the test Key Vault"
  value       = azurerm_key_vault.test_key_vault.id
}

output "azure_key_vault_uri" {
  description = "URI of the test Key Vault"
  value       = azurerm_key_vault.test_key_vault.vault_uri
}

output "azure_kv_key_id" {
  description = "ID of the test Key Vault key"
  value       = azurerm_key_vault_key.test_key.id
}

output "azure_kv_secret_id" {
  description = "ID of the test Key Vault secret"
  value       = azurerm_key_vault_secret.test_secret.id
}