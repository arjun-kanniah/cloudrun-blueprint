output "url" {
  description = "Where the app is served."
  value       = var.domain == null ? module.app.uri : module.domain[0].url
}

# Repository variables for the reusable deploy workflow.
output "github_variables" {
  description = "Set these as GitHub repository variables (Settings > Secrets and variables > Actions > Variables)."
  value = {
    GCP_PROJECT_ID   = var.project_id
    GCP_REGION       = var.region
    GCP_WIF_PROVIDER = module.project.workload_identity_provider
    GCP_DEPLOY_SA    = module.app.deploy_service_account
    IMAGE            = module.app.image
  }
}
