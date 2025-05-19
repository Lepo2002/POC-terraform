resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  dynamic "subnet" {
    for_each = var.subnets
    content {
      name           = subnet.value.name
      address_prefix = subnet.value.address_prefix
    }
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.environment}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}