resource "google_compute_network" "vpc" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "subnet" {
  count         = length(var.subnets)
  name          = "${var.environment}-subnet-${count.index + 1}"
  ip_cidr_range = var.subnets[count.index]
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  secondary_ip_range = var.secondary_ranges[count.index]
}

resource "google_compute_firewall" "default" {
  name    = "${var.environment}-firewall"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}