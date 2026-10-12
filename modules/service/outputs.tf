output "uri" {
  description = "The service's run.app URL."
  value       = google_cloud_run_v2_service.this.uri
}

output "image" {
  description = "Image path that deploys push to, without a tag."
  value       = local.image
}

output "deploy_service_account" {
  description = "For GitHub Actions: google-github-actions/auth service_account."
  value       = google_service_account.deploy.email
}

output "runtime_service_account" {
  description = "Email of the identity the service and jobs run as."
  value       = google_service_account.runtime.email
}

output "jobs" {
  description = "Job key => job name."
  value       = { for k, j in google_cloud_run_v2_job.this : k => j.name }
}
