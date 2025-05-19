output "storage_account_id" {
  description = "ID dell'account di storage"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Nome dell'account di storage"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Endpoint primario per il servizio Blob"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Endpoint primario per il servizio File"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_table_endpoint" {
  description = "Endpoint primario per il servizio Table"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_queue_endpoint" {
  description = "Endpoint primario per il servizio Queue"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_web_endpoint" {
  description = "Endpoint primario per il sito web statico (se abilitato)"
  value       = var.enable_static_website ? azurerm_storage_account.main.primary_web_endpoint : null
}

output "primary_connection_string" {
  description = "Stringa di connessione primaria per l'account di storage"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "Chiave di accesso primaria per l'account di storage"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "container_ids" {
  description = "Mappa dei nomi dei container ai loro ID"
  value       = { for name, container in azurerm_storage_container.containers : name => container.id }
}

output "file_share_ids" {
  description = "Mappa dei nomi dei file share ai loro ID"
  value       = { for name, share in azurerm_storage_share.file_shares : name => share.id }
}

output "table_ids" {
  description = "Mappa dei nomi delle tabelle ai loro ID"
  value       = { for name, table in azurerm_storage_table.tables : name => table.id }
}

output "queue_ids" {
  description = "Mappa dei nomi delle code ai loro ID"
  value       = { for name, queue in azurerm_storage_queue.queues : name => queue.id }
}

output "private_endpoint_id" {
  description = "ID del private endpoint (se creato)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.private_endpoint[0].id : null
}

output "private_endpoint_ip" {
  description = "Indirizzo IP del private endpoint (se creato)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.private_endpoint[0].private_service_connection[0].private_ip_address : null
}