resource "google_compute_firewall" "common_rules" {
  for_each     = var.common_rules
  
  name          = each.key
  project       = var.project_id
  network       = var.network_id
  direction     = each.value.direction
  source_ranges = each.value.source_ranges
  
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  
  target_tags = each.value.target_tags
  description = each.value.description
}

resource "google_compute_firewall" "environment_rules" {
  for_each     = var.environment_rules[var.environment]
  
  name          = each.key
  project       = var.project_id
  network       = var.network_id
  direction     = each.value.direction
  source_ranges = each.value.source_ranges
  
  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
  
  target_tags = each.value.target_tags
  description = each.value.description
}