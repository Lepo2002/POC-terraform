resource "google_compute_disk" "vm_disks" {
  count   = var.instance_count
  name    = "${var.disk_name}-${count.index}"
  project = var.project_id
  type    = var.disk_type
  zone    = var.zone
  size    = var.disk_size
  image   = var.disk_image
  
  labels = {
    environment = var.environment
  }
}

resource "google_compute_instance" "vm_instances" {
  count        = var.instance_count
  name         = "${var.vm_name}-${count.index}"
  project      = var.project_id
  machine_type = var.machine_type
  zone         = var.zone
  
  tags = concat(["vm", var.environment], var.additional_tags)
  
  boot_disk {
    source = google_compute_disk.vm_disks[count.index].self_link
  }
  
  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    
    dynamic "access_config" {
      for_each = var.assign_public_ip ? [1] : []
      content {
        // Ephemeral public IP
      }
    }
  }
  
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
  }
  
  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }
  
  allow_stopping_for_update = true
  
  metadata_startup_script = var.startup_script
  
  scheduling {
    preemptible         = var.preemptible
    automatic_restart   = !var.preemptible
    on_host_maintenance = var.preemptible ? "TERMINATE" : "MIGRATE"
  }
  
  lifecycle {
    ignore_changes = [attached_disk]
  }
}

resource "google_compute_instance_group" "vm_group" {
  name        = "${var.vm_name}-group"
  project     = var.project_id
  description = "Gruppo di istanze VM ${var.vm_name}"
  zone        = var.zone
  
  instances = [for instance in google_compute_instance.vm_instances : instance.self_link]
  
  named_port {
    name = "http"
    port = 80
  }
  
  named_port {
    name = "https"
    port = 443
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_disk" "additional_disks" {
  for_each = var.additional_disks
  
  name    = each.key
  project = var.project_id
  type    = each.value.type
  zone    = var.zone
  size    = each.value.size
  
  labels = {
    environment = var.environment
  }
}

resource "google_compute_attached_disk" "disk_attachments" {
  for_each = {
    for attachment in var.disk_attachments : "${attachment.disk_name}-${attachment.instance_index}" => attachment
  }
  
  disk     = google_compute_disk.additional_disks[each.value.disk_name].self_link
  instance = google_compute_instance.vm_instances[each.value.instance_index].self_link
  project  = var.project_id
  zone     = var.zone
  
  device_name = each.value.device_name
  mode        = each.value.mode
}