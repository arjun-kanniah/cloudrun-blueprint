# Project-wide pieces shared by every app: the APIs, the GitHub Actions identity pool, and a
# spending alert. Each app then uses the `service` module.

locals {
  services = concat(
    [
      "artifactregistry.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "run.googleapis.com",
      "secretmanager.googleapis.com",
      "sts.googleapis.com",
    ],
    var.billing_account == null ? [] : ["billingbudgets.googleapis.com"],
    var.extra_services,
  )

  quoted_repositories = [for r in var.github_repositories : "'${r}'"]
  repository_condition = (
    length(var.github_repositories) == 1
    ? "assertion.repository == ${local.quoted_repositories[0]}"
    : "assertion.repository in [${join(", ", local.quoted_repositories)}]"
  )
}

resource "google_project_service" "apis" {
  for_each           = toset(local.services)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- Deploys from GitHub Actions, without key files --------------------------------------

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.identity_pool_id
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  # Only the listed repositories' deploy branch can get tokens at all. Each app's deploy
  # account then trusts only its own repository (see the service module).
  attribute_condition = "${local.repository_condition} && assertion.ref == 'refs/heads/${var.github_branch}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# --- Spending alert -----------------------------------------------------------------------

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_billing_budget" "monthly" {
  count           = var.billing_account == null ? 0 : 1
  billing_account = var.billing_account
  display_name    = var.budget_name

  budget_filter {
    projects = ["projects/${data.google_project.this.number}"]
    # Count spending before credits, so alerts fire while free-trial credit is in use
    credit_types_treatment = "EXCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      units = tostring(var.monthly_budget)
    }
  }

  dynamic "threshold_rules" {
    for_each = [0.5, 0.9, 1.0]
    content {
      threshold_percent = threshold_rules.value
    }
  }

  depends_on = [google_project_service.apis]
}
