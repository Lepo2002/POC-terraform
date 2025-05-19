provider "azurerm" {
  features {}
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_subnet" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }
  
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
  
  service_endpoints    = lookup(each.value, "service_endpoints", [])
  
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "nsgs" {
  for_each = { for nsg in var.network_security_groups : nsg.name => nsg }
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_network_security_rule" "rules" {
  for_each = { for rule in var.security_rules : "${rule.nsg_name}-${rule.name}" => rule }
  
  name                        = each.value.name
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsgs[each.value.nsg_name].name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
}

resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  for_each = { for assoc in var.subnet_nsg_associations : assoc.subnet_name => assoc }
  
  subnet_id                 = azurerm_subnet.subnets[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.value.nsg_name].id
}

resource "azurerm_route_table" "route_tables" {
  for_each = { for rt in var.route_tables : rt.name => rt }
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  // disable_bgp_route_propagation attribute removed as it is not valid for azurerm_route_table resource
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_route" "routes" {
  for_each = { for route in var.routes : "${route.route_table_name}-${route.name}" => route }
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.route_tables[each.value.route_table_name].name
  
  address_prefix      = each.value.address_prefix
  next_hop_type       = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_type == "VirtualAppliance" ? each.value.next_hop_in_ip_address : null
}

resource "azurerm_subnet_route_table_association" "rt_associations" {
  for_each = { for assoc in var.subnet_route_table_associations : assoc.subnet_name => assoc }
  
  subnet_id      = azurerm_subnet.subnets[each.value.subnet_name].id
  route_table_id = azurerm_route_table.route_tables[each.value.route_table_name].id
}

resource "azurerm_public_ip" "public_ips" {
  for_each = { for pip in var.public_ips : pip.name => pip }
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = each.value.allocation_method
  sku                 = each.value.sku
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_nat_gateway" "nat_gateways" {
  for_each = { for nat in var.nat_gateways : nat.name => nat }
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  sku_name            = "Standard"
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_associations" {
  for_each = { for assoc in var.nat_gateway_public_ip_associations : "${assoc.nat_gateway_name}-${assoc.public_ip_name}" => assoc }
  
  nat_gateway_id       = azurerm_nat_gateway.nat_gateways[each.value.nat_gateway_name].id
  public_ip_address_id = azurerm_public_ip.public_ips[each.value.public_ip_name].id
}

resource "azurerm_subnet_nat_gateway_association" "nat_subnet_associations" {
  for_each = { for assoc in var.subnet_nat_gateway_associations : assoc.subnet_name => assoc }
  
  subnet_id      = azurerm_subnet.subnets[each.value.subnet_name].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateways[each.value.nat_gateway_name].id
}

resource "azurerm_private_dns_zone" "private_dns_zones" {
  for_each = toset(var.private_dns_zones)
  
  name                = each.key
  resource_group_name = var.resource_group_name
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_links" {
  for_each = { for link in var.private_dns_vnet_links : "${link.dns_zone_name}-${link.vnet_name}" => link }
  
  name                  = "${each.value.dns_zone_name}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zones[each.value.dns_zone_name].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  
  registration_enabled  = each.value.registration_enabled
}

resource "azurerm_virtual_network_peering" "vnet_peerings" {
  for_each = { for peering in var.vnet_peerings : peering.name => peering }
  
  name                      = each.value.name
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = each.value.remote_vnet_id
  
  allow_virtual_network_access = lookup(each.value, "allow_virtual_network_access", true)
  allow_forwarded_traffic      = lookup(each.value, "allow_forwarded_traffic", false)
  allow_gateway_transit        = lookup(each.value, "allow_gateway_transit", false)
  use_remote_gateways          = lookup(each.value, "use_remote_gateways", false)
}

resource "azurerm_application_security_group" "asgs" {
  for_each = { for asg in var.application_security_groups : asg.name => asg }
  
  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_firewall" "firewalls" {
  count = var.firewall != null ? 1 : 0
  
  name                = var.firewall.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  sku_name           = var.firewall.sku_name
  sku_tier           = var.firewall.sku_tier
  
  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.subnets[var.firewall.subnet_name].id
    public_ip_address_id = azurerm_public_ip.public_ips[var.firewall.public_ip_name].id
  }
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_firewall_network_rule_collection" "fw_network_rules" {
  for_each = var.firewall != null ? { for rule_col in var.firewall_network_rule_collections : rule_col.name => rule_col } : {}
  
  name                = each.value.name
  azure_firewall_name = azurerm_firewall.firewalls[0].name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.value.name
      source_addresses      = rule.value.source_addresses
      destination_addresses = rule.value.destination_addresses
      destination_ports     = rule.value.destination_ports
      protocols             = rule.value.protocols
    }
  }
}

resource "azurerm_firewall_application_rule_collection" "fw_app_rules" {
  for_each = var.firewall != null ? { for rule_col in var.firewall_application_rule_collections : rule_col.name => rule_col } : {}
  
  name                = each.value.name
  azure_firewall_name = azurerm_firewall.firewalls[0].name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      name             = rule.value.name
      source_addresses = rule.value.source_addresses
      
      dynamic "target_fqdns" {
        for_each = rule.value.target_fqdns != null ? [rule.value.target_fqdns] : []
        content {
          fqdns = target_fqdns.value
        }
      }
      
      dynamic "fqdn_tags" {
        for_each = rule.value.fqdn_tags != null ? [rule.value.fqdn_tags] : []
        content {
          tags = fqdn_tags.value
        }
      }
      
      protocol {
        port = rule.value.protocol.port
        type = rule.value.protocol.type
      }
    }
  }
}

resource "azurerm_virtual_network_gateway" "vnet_gateways" {
  count = var.virtual_network_gateway != null ? 1 : 0
  
  name                = var.virtual_network_gateway.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  type                = var.virtual_network_gateway.type
  vpn_type            = var.virtual_network_gateway.vpn_type
  sku                 = var.virtual_network_gateway.sku
  active_active       = var.virtual_network_gateway.active_active
  enable_bgp          = var.virtual_network_gateway.enable_bgp
  
  ip_configuration {
    name                 = "vnetGatewayConfig"
    subnet_id            = azurerm_subnet.subnets[var.virtual_network_gateway.subnet_name].id
    public_ip_address_id = azurerm_public_ip.public_ips[var.virtual_network_gateway.public_ip_name].id
  }
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_express_route_circuit" "express_route" {
  count = var.express_route != null ? 1 : 0
  
  name                  = var.express_route.name
  resource_group_name   = var.resource_group_name
  location              = var.location
  service_provider_name = var.express_route.service_provider_name
  peering_location      = var.express_route.peering_location
  bandwidth_in_mbps     = var.express_route.bandwidth_in_mbps
  
  sku {
    tier   = var.express_route.tier
    family = var.express_route.family
  }
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_network_ddos_protection_plan" "ddos_protection" {
  count = var.ddos_protection_plan != null ? 1 : 0
  
  name                = var.ddos_protection_plan.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_bastion_host" "bastion" {
  count = var.bastion_host != null ? 1 : 0
  
  name                = var.bastion_host.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  ip_configuration {
    name                 = "bastionIpConfig"
    subnet_id            = azurerm_subnet.subnets[var.bastion_host.subnet_name].id
    public_ip_address_id = azurerm_public_ip.public_ips[var.bastion_host.public_ip_name].id
  }
  
  tags = merge({
    environment = var.environment
  }, var.tags)
}