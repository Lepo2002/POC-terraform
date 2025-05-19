output "vm_ids" {
  description = "IDs delle istanze VM create"
  value       = google_compute_instance.vm_instances[*].id
}

output "vm_names" {
  description = "Nomi delle istanze VM create"
  value       = google_compute_instance.vm_instances[*].name
}

output "vm_self_links" {
  description = "Self-links delle istanze VM create"
  value       = google_compute_instance.vm_instances[*].self_link
}

output "vm_ip_internal" {
  description = "Indirizzi IP interni delle VM"
  value       = google_compute_instance.vm_instances[*].network_interface[0].network_ip
}

output "vm_ip_external" {
  description = "Indirizzi IP esterni delle VM (se presenti)"
  value       = [
    for instance in google_compute_instance.vm_instances :
    length(instance.network_interface[0].access_config) > 0 ? instance.network_interface[0].access_config[0].nat_ip : null
  ]
}

output "instance_group_id" {
  description = "ID del gruppo di istanze"
  value       = google_compute_instance_group.vm_group.id
}

output "instance_group_self_link" {
  description = "Self-link del gruppo di istanze"
  value       = google_compute_instance_group.vm_group.self_link
}

output "disk_ids" {
  description = "IDs dei dischi creati"
  value       = google_compute_disk.vm_disks[*].id
}

output "additional_disk_ids" {
  description = "IDs dei dischi aggiuntivi creati"
  value       = { for k, v in google_compute_disk.additional_disks : k => v.id }
}