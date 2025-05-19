
output "firewall_rules" {
  value       = google_compute_firewall.rules
  description = "Le regole firewall create"
}
