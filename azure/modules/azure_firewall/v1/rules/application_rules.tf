
# Regole applicative per Azure Firewall

locals {
  application_rule_collections = {
    "allow_web_categories" = {
      priority = 100
      action   = "Allow"
      rules = [
        {
          name             = "allow_microsoft_updates"
          source_addresses = ["10.0.0.0/8"]
          target_fqdns    = ["*.microsoft.com", "*.windowsupdate.com"]
          protocol = {
            port = "443"
            type = "Https"
          }
        }
      ]
    }
  }
}
