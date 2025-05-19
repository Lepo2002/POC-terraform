output "common_firewall_rules" {
  description = "Mappa delle regole firewall comuni create"
  value = {
    for name, rule in google_compute_firewall.common_rules : name => rule.id
  }
}

output "environment_firewall_rules" {
  description = "Mappa delle regole firewall specifiche per ambiente create"
  value = {
    for name, rule in google_compute_firewall.environment_rules : name => rule.id
  }
}