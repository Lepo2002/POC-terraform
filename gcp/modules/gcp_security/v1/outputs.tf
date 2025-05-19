output "key_ring_id" {
  description = "ID del key ring KMS"
  value       = var.enable_kms ? google_kms_key_ring.key_ring[0].id : null
}

output "key_ring_name" {
  description = "Nome del key ring KMS"
  value       = var.enable_kms ? google_kms_key_ring.key_ring[0].name : null
}

output "crypto_key_ids" {
  description = "Mappa degli ID delle chiavi di crittografia"
  value       = { for k, v in google_kms_crypto_key.crypto_keys : k => v.id }
}

output "crypto_key_versions" {
  description = "Mappa delle versioni delle chiavi di crittografia"
  value       = { for k, v in google_kms_crypto_key.crypto_keys : k => v.version }
}

output "secret_ids" {
  description = "Mappa degli ID dei segreti creati"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.id }
}

output "binary_authorization_policy_id" {
  description = "ID della policy di Binary Authorization"
  value       = var.enable_binary_authorization ? google_binary_authorization_policy.policy[0].id : null
}

output "cloud_armor_policy_id" {
  description = "ID della policy Cloud Armor"
  value       = var.enable_cloud_armor ? google_compute_security_policy.cloud_armor_policy[0].id : null
}

output "cloud_armor_policy_self_link" {
  description = "Self-link della policy Cloud Armor"
  value       = var.enable_cloud_armor ? google_compute_security_policy.cloud_armor_policy[0].self_link : null
}

output "ssl_policy_id" {
  description = "ID della policy SSL"
  value       = var.enable_ssl_policy ? google_compute_ssl_policy.ssl_policy[0].id : null
}

output "ssl_policy_self_link" {
  description = "Self-link della policy SSL"
  value       = var.enable_ssl_policy ? google_compute_ssl_policy.ssl_policy[0].self_link : null
}

output "network_security_policy_ids" {
  description = "Mappa degli ID delle Network Security Policies"
  value       = { for k, v in google_compute_network_security_policy.security_policies : k => v.id }
}