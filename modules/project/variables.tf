variable "project_id" {
  description = "Google Cloud project that hosts the apps."
  type        = string
}

variable "extra_services" {
  description = "APIs to enable on top of the ones Cloud Run apps need."
  type        = list(string)
  default     = []
}

variable "github_repositories" {
  description = "owner/name of each GitHub repository allowed to deploy into the project."
  type        = list(string)

  validation {
    condition     = length(var.github_repositories) > 0 && alltrue([for r in var.github_repositories : can(regex("^[\\w.-]+/[\\w.-]+$", r))])
    error_message = "List at least one repository, each as owner/name."
  }
}

variable "github_branch" {
  description = "The only branch that can get deploy credentials."
  type        = string
  default     = "main"
}

variable "identity_pool_id" {
  description = "ID of the Workload Identity pool for GitHub Actions. Pool IDs stay reserved for 30 days after deletion."
  type        = string
  default     = "github"
}

variable "billing_account" {
  description = "Billing account ID (XXXXXX-XXXXXX-XXXXXX) for the budget alert, or null for no budget."
  type        = string
  default     = null
}

variable "budget_name" {
  description = "Display name of the budget."
  type        = string
  default     = "Monthly spend"
}

variable "monthly_budget" {
  description = "Monthly budget in the billing account's currency; alerts at 50, 90 and 100%."
  type        = number
  default     = 20
}
