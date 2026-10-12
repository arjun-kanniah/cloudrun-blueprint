# One Cloud Run app: its image repository, a runtime identity that can read only its own
# secrets, the service, optional jobs, and a deploy identity that only its GitHub repository
# can use.

locals {
  display_name = coalesce(var.display_name, var.name)
  image        = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}/${var.name}"

  # The first apply runs a placeholder; deploys replace the image (see the lifecycle blocks).
  placeholder_image = "us-docker.pkg.dev/cloudrun/container/hello"

  secret_names = { for env, id in var.secrets : env => "projects/${var.project_id}/secrets/${id}" }
}

# --- Container images ---------------------------------------------------------------------

resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  repository_id = var.name
  location      = var.region
  format        = "DOCKER"
  description   = "${local.display_name} images"

  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.keep_images
    }
  }
  cleanup_policies {
    id     = "delete-older"
    action = "DELETE"
    condition {
      older_than = "86400s"
    }
  }
}

# --- Runtime identity and secrets ---------------------------------------------------------

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "${var.name}-run"
  display_name = "${local.display_name} runtime"
  description  = "Runs the ${local.display_name} service and jobs. Reads only ${local.display_name}'s secrets."
}

resource "google_secret_manager_secret_iam_member" "runtime" {
  for_each  = local.secret_names
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.runtime.member
}

# --- The service --------------------------------------------------------------------------

resource "google_cloud_run_v2_service" "this" {
  project             = var.project_id
  name                = var.name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account                  = google_service_account.runtime.email
    max_instance_request_concurrency = var.concurrency
    timeout                          = var.timeout

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = local.placeholder_image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "startup_probe" {
        for_each = var.health_path == null ? [] : [var.health_path]
        content {
          http_get {
            path = startup_probe.value
          }
          period_seconds    = 2
          failure_threshold = 30
        }
      }
    }
  }

  lifecycle {
    # Deploys (GitHub Actions) set the image; Terraform owns everything else.
    ignore_changes = [template[0].containers[0].image, client, client_version]
  }

  # The first revision fails to start if it can't read its secrets yet.
  depends_on = [google_secret_manager_secret_iam_member.runtime]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  count    = var.public ? 1 : 0
  project  = var.project_id
  name     = google_cloud_run_v2_service.this.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- Jobs ---------------------------------------------------------------------------------

resource "google_cloud_run_v2_job" "this" {
  for_each            = var.jobs
  project             = var.project_id
  name                = "${var.name}-${each.key}"
  location            = var.region
  deletion_protection = false

  template {
    template {
      service_account = google_service_account.runtime.email
      max_retries     = each.value.max_retries
      timeout         = each.value.timeout

      containers {
        image   = local.placeholder_image
        command = each.value.command
        args    = each.value.args

        resources {
          limits = {
            cpu    = each.value.cpu
            memory = each.value.memory
          }
        }

        dynamic "env" {
          for_each = each.value.env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = toset(each.value.secret_env)
          content {
            name = env.value
            value_source {
              secret_key_ref {
                secret  = var.secrets[env.value]
                version = "latest"
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image, client, client_version]
  }

  depends_on = [google_secret_manager_secret_iam_member.runtime]
}

# --- Deploys from GitHub Actions ----------------------------------------------------------

resource "google_service_account" "deploy" {
  project      = var.project_id
  account_id   = "${var.name}-deploy"
  display_name = "${local.display_name} deploy (GitHub Actions)"
  description  = "Pushes images and deploys ${local.display_name}. Usable only from ${var.github_repository}."
}

resource "google_service_account_iam_member" "deploy_from_github" {
  service_account_id = google_service_account.deploy.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${var.workload_identity_pool_name}/attribute.repository/${var.github_repository}"
}

resource "google_artifact_registry_repository_iam_member" "deploy_push" {
  project    = var.project_id
  repository = google_artifact_registry_repository.this.name
  location   = var.region
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.deploy.member
}

resource "google_cloud_run_v2_service_iam_member" "deploy_service" {
  project  = var.project_id
  name     = google_cloud_run_v2_service.this.name
  location = var.region
  role     = "roles/run.developer"
  member   = google_service_account.deploy.member
}

resource "google_cloud_run_v2_job_iam_member" "deploy_job" {
  for_each = google_cloud_run_v2_job.this
  project  = var.project_id
  name     = each.value.name
  location = var.region
  role     = "roles/run.developer"
  member   = google_service_account.deploy.member
}

# Deploying a revision that runs as the runtime account requires acting as it.
resource "google_service_account_iam_member" "deploy_as_runtime" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.deploy.member
}
