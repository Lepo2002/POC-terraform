
provider "azurerm" {
  features {}
}

resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name           = var.sku_name
  sku_tier           = var.sku_tier

  ip_configuration {
    name                 = "firewall-ipconfig"
    subnet_id            = var.subnet_id
    public_ip_address_id = var.public_ip_address_id
  }

  tags = merge({
    environment = var.environment
  }, var.tags)
}

resource "azurerm_firewall_policy" "policy" {
  name                = "${var.firewall_name}-policy"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_firewall_policy_rule_collection_group" "rules" {
  name               = "fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 100

  dynamic "application_rule_collection" {
    for_each = var.application_rules
    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name = rule.value.name
          source_addresses = rule.value.source_addresses
          destination_fqdns = rule.value.destination_fqdns

          protocols {
            type = rule.value.protocol.type
            port = rule.value.protocol.port
          }
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = var.network_rules
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          protocols            = rule.value.protocols
        }
      }
    }
  }
}
