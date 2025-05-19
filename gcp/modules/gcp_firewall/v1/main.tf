
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules
  
  name        = each.key
  network     = var.vpc_network
  project     = var.project_id
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  source_ranges      = each.value.source_ranges
  destination_ranges = each.value.destination_ranges
  source_tags       = each.value.source_tags
  target_tags       = each.value.target_tags

  dynamic "log_config" {
    for_each = each.value.enable_logging ? [1] : []
    content {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }
}
