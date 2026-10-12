mock_provider "google" {}

variables {
  project_id          = "demo-project"
  github_repositories = ["octo/app"]
}

run "one_repository" {
  command = plan

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.attribute_condition == "assertion.repository == 'octo/app' && assertion.ref == 'refs/heads/main'"
    error_message = "A single repository should get a plain equality condition on main."
  }

  assert {
    condition     = length(google_billing_budget.monthly) == 0 && !contains(keys(google_project_service.apis), "billingbudgets.googleapis.com")
    error_message = "No billing account means no budget and no budgets API."
  }
}

run "several_repositories_and_a_budget" {
  command = plan

  variables {
    github_repositories = ["octo/app", "octo/api"]
    github_branch       = "release"
    billing_account     = "000000-000000-000000"
    extra_services      = ["sqladmin.googleapis.com"]
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.attribute_condition == "assertion.repository in ['octo/app', 'octo/api'] && assertion.ref == 'refs/heads/release'"
    error_message = "Several repositories should be matched with `in`, on the chosen branch."
  }

  assert {
    condition     = length(google_billing_budget.monthly) == 1
    error_message = "A billing account should create the budget."
  }

  assert {
    condition     = alltrue([for s in ["billingbudgets.googleapis.com", "sqladmin.googleapis.com", "run.googleapis.com"] : contains(keys(google_project_service.apis), s)])
    error_message = "Extra and budget APIs should be enabled alongside the base set."
  }
}

run "rejects_a_bad_repository" {
  command = plan

  variables {
    github_repositories = ["not a repo"]
  }

  expect_failures = [var.github_repositories]
}
