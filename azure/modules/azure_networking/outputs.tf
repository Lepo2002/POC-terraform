output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  value = azurerm_virtual_network.vnet.address_space
}

output "subnet_ids" {
  value = { for name, subnet in azurerm_subnet.subnets : name => subnet.id }
}

output "subnet_address_prefixes" {
  value = { for name, subnet in azurerm_subnet.subnets : name => subnet.address_prefixes[0] }
}

output "nsg_ids" {
  value = { for name, nsg in azurerm_network_security_group.nsgs : name => nsg.id }
}

output "route_table_ids" {
  value = { for name, rt in azurerm_route_table.route_tables : name => rt.id }
}

output "public_ip_ids" {
  value = { for name, pip in azurerm_public_ip.public_ips : name => pip.id }
}

output "public_ip_addresses" {
  value = { for name, pip in azurerm_public_ip.public_ips : name => pip.ip_address }
}

output "nat_gateway_ids" {
  value = { for name, nat in azurerm_nat_gateway.nat_gateways : name => nat.id }
}

output "private_dns_zone_ids" {
  value = { for name, zone in azurerm_private_dns_zone.private_dns_zones : name => zone.id }
}

output "application_security_group_ids" {
  value = { for name, asg in azurerm_application_security_group.asgs : name => asg.id }
}

output "firewall_id" {
  value = var.firewall != null ? azurerm_firewall.firewalls[0].id : null
}

output "firewall_private_ip" {
  value = var.firewall != null ? azurerm_firewall.firewalls[0].ip_configuration[0].private_ip_address : null
}

output "firewall_public_ip" {
  value = var.firewall != null ? azurerm_public_ip.public_ips[var.firewall.public_ip_name].ip_address : null
}

output "virtual_network_gateway_id" {
  value = var.virtual_network_gateway != null ? azurerm_virtual_network_gateway.vnet_gateways[0].id : null
}

output "express_route_circuit_id" {
  value = var.express_route != null ? azurerm_express_route_circuit.express_route[0].id : null
}

output "express_route_service_key" {
  value = var.express_route != null ? azurerm_express_route_circuit.express_route[0].service_key : null
  sensitive = true
}

output "ddos_protection_plan_id" {
  value = var.ddos_protection_plan != null ? azurerm_network_ddos_protection_plan.ddos_protection[0].id : null
}

output "bastion_host_id" {
  value = var.bastion_host != null ? azurerm_bastion_host.bastion[0].id : null
}