output "instance_name" {
  value = azurerm_mssql_server.main.name
}

output "instance_id" {
  value = azurerm_mssql_server.main.id
}

output "database_name" {
  value = azurerm_mssql_database.database.name
}

output "database_id" {
  value = azurerm_mssql_database.database.id
}

output "connection_string" {
  value     = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};Persist Security Info=False;User ID=${var.database_username};Password=${var.database_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Integrated;"
  sensitive = true
}

output "private_endpoint_id" {
  value = var.private_network ? azurerm_private_endpoint.database_endpoint[0].id : null
}

output "fully_qualified_domain_name" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}