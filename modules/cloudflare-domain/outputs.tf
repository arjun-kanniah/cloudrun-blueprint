output "url" {
  description = "The custom domain's URL."
  value       = "https://${var.hostname}"
}

output "proxy_secret_id" {
  description = "Secret Manager ID of the shared secret. Pass it to the service module's secrets so the service can read it."
  value       = google_secret_manager_secret.proxy.secret_id
  # The service shouldn't start a revision that reads the secret before it has a value.
  depends_on = [google_secret_manager_secret_version.proxy]
}

output "zone_id" {
  description = "The zone's ID, for other records in it."
  value       = data.cloudflare_zone.this.zone_id
}

output "account_id" {
  description = "The Cloudflare account that owns the zone."
  value       = data.cloudflare_zone.this.account.id
}
