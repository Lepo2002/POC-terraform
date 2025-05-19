provider "azurerm" {
  features {}
}

resource "azurerm_cognitive_account" "main" {
  name                  = var.account_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = var.account_kind
  sku_name              = var.sku_name
  custom_subdomain_name = var.custom_subdomain_name

  network_acls {
    default_action             = var.network_default_action
    ip_rules                   = var.network_ip_rules
  }

  tags = merge(
    {
      environment = var.environment
    },
    var.additional_tags
  )
}

resource "azurerm_cognitive_deployment" "model_deployments" {
  for_each = var.model_deployments

  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.main.id
  
  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name = var.sku_name
  }
}

resource "azurerm_cognitive_account_customer_managed_key" "cmk" {
  count = var.enable_customer_managed_key ? 1 : 0

  cognitive_account_id = azurerm_cognitive_account.main.id
  key_vault_key_id     = var.customer_managed_key_id
}

resource "azurerm_private_endpoint" "ai_private_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.account_name}-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.account_name}-privateserviceconnection"
    private_connection_resource_id = azurerm_cognitive_account.main.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }
}

resource "azurerm_cognitive_account_network_rules" "network_rules" {
  count = length(var.network_subnet_ids) > 0 || length(var.network_ip_rules) > 0 ? 1 : 0

  cognitive_account_id = azurerm_cognitive_account.main.id

  default_action = var.network_default_action
  virtual_network_subnet_ids = var.network_subnet_ids
  ip_rules                   = var.network_ip_rules
}