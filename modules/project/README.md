# project

Once per Google Cloud project: enables the APIs Cloud Run apps need, creates a Workload Identity
pool for GitHub Actions that accepts only `github_repositories` on `github_branch`, and, given
a `billing_account`, a monthly budget with alerts at 50, 90 and 100% of spending before credits.

Pass `workload_identity_pool_name` to each [service](../service) and use
`workload_identity_provider` in the deploy workflow. Inputs are described in
[variables.tf](variables.tf), outputs in [outputs.tf](outputs.tf).
