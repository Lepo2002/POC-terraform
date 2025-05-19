
# Regole di rete per Azure Firewall

locals {
  network_rule_collections = {
    "allow_internal" = {
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "allow_vnet_internal"
          source_addresses      = ["10.0.0.0/8"]
          destination_addresses = ["10.0.0.0/8"]
          destination_ports     = ["*"]
          protocols            = ["Any"]
        }
      ]
    }
    "allow_internet_outbound" = {
      priority = 200
      action   = "Allow"
      rules = [
        {
          name                  = "web_outbound"
          source_addresses      = ["10.0.0.0/8"]
          destination_addresses = ["*"]
          destination_ports     = ["80", "443"]
          protocols            = ["TCP"]
        }
      ]
    }
  }
}
