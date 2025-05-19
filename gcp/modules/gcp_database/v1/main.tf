resource "google_sql_database_instance" "main" {
  name                = var.instance_name
  project             = var.project_id
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.enable_deletion_protection
  
  settings {
    tier              = var.database_tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    
    backup_configuration {
      enabled            = var.backup_enabled
      binary_log_enabled = var.backup_enabled && var.enable_binary_logging
      start_time         = var.backup_start_time
      location           = var.backup_location
    }
    
    maintenance_window {
      day          = var.maintenance_day
      hour         = var.maintenance_hour
      update_track = var.maintenance_update_track
    }
    
    ip_configuration {
      ipv4_enabled    = !var.private_network
      private_network = var.private_network ? var.network_id : null
      
      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.key
          value = authorized_networks.value
        }
      }
    }
    
    user_labels = merge({
      environment = var.environment
    }, var.additional_labels)
    
    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }
    
    dynamic "database_flags" {
      for_each = var.additional_database_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  charset  = var.database_charset
  collation = var.database_collation
}

resource "google_sql_user" "users" {
  for_each = var.additional_users

  name     = each.key
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = each.value
}

resource "google_sql_user" "main_user" {
  name     = var.database_username
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = var.database_password
}

resource "google_compute_global_address" "private_ip_address" {
  count = var.private_network ? 1 : 0
  
  name          = "private-ip-address-${var.instance_name}"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.private_network ? 1 : 0
  
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}