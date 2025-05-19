# Configurazione del cluster GKE
resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.regional ? var.region : var.zone
  project            = var.project_id
  min_master_version = var.kubernetes_version

  # Configurazione della rete
  network    = var.network
  subnetwork = var.subnetwork

  # Configurazione IP aliasing
  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Configurazione del controllo degli accessi
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Configurazione della sicurezza
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }

  # Configurazione del controllo degli accessi
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Configurazione del node pool di default
  remove_default_node_pool = true
  initial_node_count       = 1
}

# Node pool principale
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.regional ? var.region : var.zone
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.initial_node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]

    labels = var.node_labels
    tags   = var.node_tags

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_container_cluster" "dr" {
  count    = var.enable_dr ? 1 : 0
  name     = "${var.cluster_name}-dr"
  project  = var.project_id
  location = var.dr_location

  network    = var.network_id
  subnetwork = var.subnetwork_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = var.private_cluster
    enable_private_endpoint = var.private_endpoint
    master_ipv4_cidr_block  = var.private_cluster ? var.master_ipv4_cidr_block : null
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  min_master_version = var.kubernetes_version
  
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  
  networking_mode = "VPC_NATIVE"
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"
    }
  }

  resource_labels = {
    environment = var.environment
    type        = "disaster-recovery"
  }

  lifecycle {
    ignore_changes = [
      node_config,
    ]
  }
}

resource "google_container_node_pool" "dr_nodes" {
  count      = var.enable_dr ? 1 : 0
  name       = "${var.cluster_name}-dr-node-pool"
  project    = var.project_id
  location   = var.dr_location
  cluster    = google_container_cluster.dr[0].name
  node_count = var.dr_node_count

  node_config {
    preemptible  = false  
    machine_type = var.node_machine_type

    service_account = var.service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      environment = var.environment
      type        = "disaster-recovery"
    }

    disk_type    = "pd-standard"
    disk_size_gb = 100

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}