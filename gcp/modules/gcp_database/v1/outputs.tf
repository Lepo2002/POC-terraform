output "instance_name" {
  description = "Nome dell'istanza database"
  value       = google_sql_database_instance.main.name
}

output "instance_id" {
  description = "ID univoco dell'istanza database"
  value       = google_sql_database_instance.main.id
}

output "instance_connection_name" {
  description = "Nome di connessione dell'istanza database"
  value       = google_sql_database_instance.main.connection_name
}

output "instance_self_link" {
  description = "Self-link dell'istanza database"
  value       = google_sql_database_instance.main.self_link
}

output "instance_ip_address" {
  description = "Indirizzo IP dell'istanza database (solo per istanze pubbliche)"
  value       = google_sql_database_instance.main.public_ip_address
}

output "instance_private_ip_address" {
  description = "Indirizzo IP privato dell'istanza database (solo per istanze private)"
  value       = google_sql_database_instance.main.private_ip_address
}

output "instance_first_ip_address" {
  description = "Primo indirizzo IP disponibile dell'istanza database"
  value       = google_sql_database_instance.main.first_ip_address
}

output "database_name" {
  description = "Nome del database creato"
  value       = google_sql_database.database.name
}

output "connection_name" {
  description = "Nome di connessione dell'istanza database"
  value       = google_sql_database_instance.main.connection_name
}

output "database_user" {
  description = "Nome utente principale del database"
  value       = google_sql_user.main_user.name
}

output "additional_users" {
  description = "Nomi degli utenti aggiuntivi del database"
  value       = [for user in google_sql_user.users : user.name]
}

output "database_version" {
  description = "Versione del database"
  value       = google_sql_database_instance.main.database_version
}