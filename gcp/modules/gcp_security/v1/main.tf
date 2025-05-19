resource "google_kms_key_ring" "key_ring" {
  count = var.enable_kms ? 1 : 0
  
  name     = "${var.environment}-key-ring"
  project  = var.project_id
  location = var.region
}

resource "google_kms_crypto_key" "crypto_keys" {
  for_each = var.enable_kms ? var.crypto_keys : {}
  
  name            = each.key
  key_ring        = google_kms_key_ring.key_ring[0].id
  rotation_period = each.value.rotation_period
  
  version_template {
    algorithm        = each.value.algorithm
    protection_level = each.value.protection_level
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets
  
  secret_id = each.key
  project   = var.project_id
  
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  
  labels = {
    environment = var.environment
  }
}

resource "google_secret_manager_secret_version" "secret_versions" {
  for_each = var.secrets
  
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value.data
}

resource "google_secret_manager_secret_iam_binding" "secret_iam_bindings" {
  for_each = var.secret_access_bindings
  
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].id
  role      = each.value.role
  members   = each.value.members
  project   = var.project_id
}

resource "google_binary_authorization_policy" "policy" {
  count = var.enable_binary_authorization ? 1 : 0
  
  project               = var.project_id
  global_policy_evaluation_mode = var.binary_auth_policy_mode
  
  default_admission_rule {
    evaluation_mode  = var.binary_auth_default_rule
    enforcement_mode = var.binary_auth_enforce ? "ENFORCED_BLOCK_AND_AUDIT_LOG" : "DRYRUN_AUDIT_LOG_ONLY"
  }
  
  dynamic "admission_whitelist_patterns" {
    for_each = var.binary_auth_whitelist_images
    content {
      name_pattern = admission_whitelist_patterns.value
    }
  }
}

resource "google_compute_security_policy" "cloud_armor_policy" {
  count = var.enable_cloud_armor ? 1 : 0
  
  name        = "${var.environment}-security-policy"
  project     = var.project_id
  description = "Security policy per proteggere le risorse nell'ambiente ${var.environment}"
  
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = var.enable_ddos_protection
    }
  }
  
  dynamic "rule" {
    for_each = var.cloud_armor_rules
    content {
      action   = rule.value.action
      priority = rule.value.priority
      match {
        expr {
          expression = rule.value.expression
        }
      }
      description = rule.value.description
    }
  }
  
  rule {
    action   = "deny(403)"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }
}

resource "google_compute_ssl_policy" "ssl_policy" {
  count = var.enable_ssl_policy ? 1 : 0
  
  name            = "${var.environment}-ssl-policy"
  project         = var.project_id
  profile         = var.ssl_policy_profile
  min_tls_version = var.ssl_min_tls_version
}

resource "google_compute_network_security_policy" "security_policies" {
  for_each = var.enable_network_security_policies ? var.network_security_policies : {}
  
  name        = each.key
  project     = var.project_id
  description = each.value.description
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      priority = rule.value.priority
      description = rule.value.description
      
      match {
        layer4_configs {
          ip_protocol = rule.value.ip_protocol
          ports       = rule.value.ports
        }
        src_ip_ranges  = rule.value.src_ip_ranges
        dest_ip_ranges = rule.value.dest_ip_ranges
      }
      
      action = rule.value.action
    }
  }
}