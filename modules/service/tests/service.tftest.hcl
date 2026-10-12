mock_provider "google" {}

variables {
  project_id                  = "demo-project"
  region                      = "us-east5"
  name                        = "hello"
  github_repository           = "octo/hello"
  workload_identity_pool_name = "projects/123/locations/global/workloadIdentityPools/github"
}

run "defaults" {
  command = plan

  assert {
    condition     = local.image == "us-east5-docker.pkg.dev/demo-project/hello/hello"
    error_message = "Unexpected image path."
  }

  assert {
    condition     = google_service_account.runtime.account_id == "hello-run" && google_service_account.deploy.account_id == "hello-deploy"
    error_message = "Service accounts should be named after the service."
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 1
    error_message = "Services are public by default."
  }

  assert {
    condition     = length(google_cloud_run_v2_service.this.template[0].containers[0].startup_probe) == 0
    error_message = "No health_path means Cloud Run's default probe."
  }

  assert {
    condition     = google_service_account_iam_member.deploy_from_github.member == "principalSet://iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/github/attribute.repository/octo/hello"
    error_message = "Only the app's own repository may use the deploy account."
  }
}

run "secrets_and_jobs" {
  command = plan

  variables {
    public      = false
    health_path = "/healthz"
    env         = { MODE = "demo" }
    secrets = {
      DATABASE_URL = "database-url"
      API_KEY      = "api-key"
    }
    jobs = {
      migrate = { args = ["migrate"], secret_env = ["DATABASE_URL"] }
    }
  }

  assert {
    condition     = google_secret_manager_secret_iam_member.runtime["DATABASE_URL"].secret_id == "projects/demo-project/secrets/database-url"
    error_message = "Secret access should be granted per secret, by full name."
  }

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 0
    error_message = "public = false should not grant allUsers."
  }

  assert {
    condition     = google_cloud_run_v2_job.this["migrate"].name == "hello-migrate"
    error_message = "Jobs should be named <name>-<key>."
  }

  assert {
    condition     = [for e in google_cloud_run_v2_job.this["migrate"].template[0].template[0].containers[0].env : e.name] == ["DATABASE_URL"]
    error_message = "A job should receive only the secrets listed in its secret_env."
  }

  assert {
    condition     = google_cloud_run_v2_service.this.template[0].containers[0].startup_probe[0].http_get[0].path == "/healthz"
    error_message = "health_path should set an HTTP startup probe."
  }
}

run "rejects_a_job_secret_that_is_not_granted" {
  command = plan

  variables {
    jobs = { migrate = { secret_env = ["DATABASE_URL"] } }
  }

  expect_failures = [var.jobs]
}

run "rejects_a_long_name" {
  command = plan

  variables {
    name = "a-name-much-too-long-for-ids"
  }

  expect_failures = [var.name]
}
