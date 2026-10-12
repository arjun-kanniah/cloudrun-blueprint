output "workload_identity_pool_name" {
  description = "Full name of the GitHub identity pool, for the service module."
  value       = google_iam_workload_identity_pool.github.name
}

output "workload_identity_provider" {
  description = "For GitHub Actions: google-github-actions/auth workload_identity_provider."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "services" {
  description = "The enabled APIs. Depend on this before creating resources that need them."
  value       = [for s in google_project_service.apis : s.service]
}
