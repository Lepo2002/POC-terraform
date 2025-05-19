provider "azurerm" {
  features {}
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  account_kind             = var.account_kind
  
  access_tier                     = var.access_tier
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_public_access
  
  is_hns_enabled    = var.enable_hierarchical_namespace
  nfsv3_enabled     = var.enable_nfsv3
  
  blob_properties {
    dynamic "cors_rule" {
      for_each = var.blob_cors_rules
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
    
    versioning_enabled          = var.enable_blob_versioning
    change_feed_enabled         = var.enable_change_feed
    last_access_time_enabled    = var.enable_last_access_time_tracking
    
    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_retention_days > 0 ? [1] : []
      content {
        days = var.blob_soft_delete_retention_days
      }
    }
    
    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_retention_days > 0 ? [1] : []
      content {
        days = var.container_soft_delete_retention_days
      }
    }
  }
  
  network_rules {
    default_action             = var.network_default_action
    bypass                     = var.network_bypass
    ip_rules                   = var.ip_rules
    virtual_network_subnet_ids = var.subnet_ids
  }
  
  dynamic "static_website" {
    for_each = var.enable_static_website ? [1] : []
    content {
      index_document     = var.static_website_index_document
      error_404_document = var.static_website_error_document
    }
  }
  
  tags = merge({
    environment = var.environment
  }, var.tags)

}

resource "azurerm_storage_container" "containers" {
  for_each = { for container in var.containers : container.name => container }
  
  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}

resource "azurerm_storage_share" "file_shares" {
  for_each = { for share in var.file_shares : share.name => share }
  
  name                 = each.value.name
  storage_account_name = azurerm_storage_account.main.name
  quota                = each.value.quota
  access_tier          = lookup(each.value, "access_tier", null)
  
  acl {
    id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI"
    
    access_policy {
      permissions = lookup(each.value, "permissions", "rwdl")
      start       = lookup(each.value, "start_date", null)
      expiry      = lookup(each.value, "expiry_date", null)
    }
  }
}

resource "azurerm_storage_table" "tables" {
  for_each = toset(var.tables)
  
  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)
  
  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_role_assignment" "blob_data_contributors" {
  for_each = toset(var.blob_data_contributors)
  
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "blob_data_readers" {
  for_each = toset(var.blob_data_readers)
  
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

resource "azurerm_storage_management_policy" "lifecycle_policy" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0
  
  storage_account_id = azurerm_storage_account.main.id
  
  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.value.name
      enabled = true
      
      filters {
        prefix_match = lookup(rule.value, "prefix_match", [])
        blob_types   = lookup(rule.value, "blob_types", ["blockBlob"])
      }
      
      actions {
        dynamic "base_blob" {
          for_each = lookup(rule.value, "base_blob", null) != null ? [rule.value.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than        = lookup(base_blob.value, "tier_to_cool_after_days", null)
            tier_to_archive_after_days_since_modification_greater_than     = lookup(base_blob.value, "tier_to_archive_after_days", null)
            delete_after_days_since_modification_greater_than              = lookup(base_blob.value, "delete_after_days", null)
          }
        }
        
        dynamic "snapshot" {
          for_each = lookup(rule.value, "snapshot", null) != null ? [rule.value.snapshot] : []
          content {
            delete_after_days_since_creation_greater_than = lookup(snapshot.value, "delete_after_days", null)
          }
        }
        
        dynamic "version" {
          for_each = lookup(rule.value, "version", null) != null ? [rule.value.version] : []
          content {
            delete_after_days_since_creation = lookup(version.value, "delete_after_days", null)
          }
        }
      }
    }
  }
}

resource "azurerm_advanced_threat_protection" "threat_protection" {
  count              = var.enable_advanced_threat_protection ? 1 : 0
  target_resource_id = azurerm_storage_account.main.id
  enabled            = true
}

resource "azurerm_private_endpoint" "private_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.storage_account_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  
  private_service_connection {
    name                           = "${var.storage_account_name}-pec"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = var.private_endpoint_subresources
  }
  
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}