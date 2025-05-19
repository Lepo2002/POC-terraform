resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  
  delete_default_routes_on_create = var.delete_default_routes
}

resource "google_compute_subnetwork" "subnets" {
  for_each      = { for subnet in var.subnets : subnet.name => subnet }
  name          = each.value.name
  project       = var.project_id
  ip_cidr_range = each.value.cidr
  region        = each.value.region
  network       = google_compute_network.vpc.id
  
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.name
      ip_cidr_range = secondary_ip_range.value.cidr
    }
  }
  
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  count   = var.create_nat_gateway ? 1 : 0
  name    = "${var.vpc_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  count                              = var.create_nat_gateway ? 1 : 0
  name                               = "${var.vpc_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "private_ip_alloc" {
  count         = var.create_private_service_access ? 1 : 0
  name          = "${var.vpc_name}-private-ip-alloc"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_service_connection" {
  count                   = var.create_private_service_access ? 1 : 0
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc[0].name]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.vpc_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.id
  
  allow {
    protocol = "icmp"
  }
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  source_ranges = [for subnet in var.subnets : subnet.cidr]
}

resource "google_compute_route" "routes" {
  for_each     = var.routes
  
  name         = each.key
  project      = var.project_id
  network      = google_compute_network.vpc.id
  dest_range   = each.value.destination_range
  priority     = each.value.priority
  
  dynamic "next_hop_instance" {
    for_each = each.value.next_hop_type == "instance" ? [1] : []
    content {
      instance = each.value.next_hop_target
      zone     = each.value.next_hop_zone
    }
  }
  
  dynamic "next_hop_ip" {
    for_each = each.value.next_hop_type == "ip" ? [1] : []
    content {
      next_hop_ip = each.value.next_hop_target
    }
  }
  
  dynamic "next_hop_gateway" {
    for_each = each.value.next_hop_type == "gateway" ? [1] : []
    content {
      next_hop_gateway = each.value.next_hop_target
    }
  }
  
  dynamic "next_hop_ilb" {
    for_each = each.value.next_hop_type == "ilb" ? [1] : []
    content {
      next_hop_ilb = each.value.next_hop_target
    }
  }
}