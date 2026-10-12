# A public app with a database-migration job, deployed from GitHub Actions, with an optional
# custom domain. Create the secret first: gcloud secrets create database-url, then add a version.

module "project" {
  source = "../../modules/project"

  project_id          = var.project_id
  github_repositories = [var.github_repository]
  billing_account     = var.billing_account
}

module "app" {
  source = "../../modules/service"

  project_id                  = var.project_id
  region                      = var.region
  name                        = "hello"
  github_repository           = var.github_repository
  workload_identity_pool_name = module.project.workload_identity_pool_name
  health_path                 = "/healthz"

  env = { LOG_LEVEL = "info" }

  secrets = merge(
    { DATABASE_URL = "database-url" },
    var.domain == null ? {} : { PROXY_SECRET = module.domain[0].proxy_secret_id },
  )

  jobs = {
    migrate = { args = ["migrate"], secret_env = ["DATABASE_URL"] }
  }

  depends_on = [module.project]
}

module "domain" {
  source = "../../modules/cloudflare-domain"
  count  = var.domain == null ? 0 : 1

  project_id = var.project_id
  zone       = var.domain.zone
  hostname   = var.domain.hostname
  origin_url = module.app.uri
  name       = "hello"

  depends_on = [module.project]
}
