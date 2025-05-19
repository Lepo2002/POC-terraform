
output "firewall_id" {
  value       = azurerm_firewall.firewall.id
  description = "ID del firewall Azure"
}

output "firewall_private_ip" {
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  description = "IP privato del firewall"
}

output "policy_id" {
  value       = azurerm_firewall_policy.policy.id
  description = "ID della policy del firewall"
}
