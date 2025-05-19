provider "azurerm" {
  features {}
}

resource "azurerm_mssql_server" "main" {
  name                         = var.instance_name
  resource_group_name          = var.resource_group_name
  location                     = var.region
  version                      = var.database_version
  administrator_login          = var.database_username
  administrator_login_password = var.database_password
  
  public_network_access_enabled = !var.private_network
  
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_database" "database" {
  name      = var.database_name
  server_id = azurerm_mssql_server.main.id
  
  sku_name = var.database_tier
  
  short_term_retention_policy {
    retention_days = 7
  }
  
  long_term_retention_policy {
    weekly_retention  = var.backup_enabled ? "P1W" : null
    monthly_retention = var.backup_enabled ? "P1M" : null
    yearly_retention  = var.backup_enabled ? "P1Y" : null
  }
}

resource "azurerm_mssql_database_extended_auditing_policy" "auditing" {
  database_id = azurerm_mssql_database.database.id
  enabled     = true
}

resource "azurerm_private_endpoint" "database_endpoint" {
  count               = var.private_network ? 1 : 0
  name                = "${var.instance_name}-private-endpoint"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = "${var.instance_name}-privateserviceconnection"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}

resource "azurerm_mssql_firewall_rule" "network_rules" {
  for_each = var.authorized_networks

  name             = each.key
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}