variable "project_id" {
  description = "Google Cloud project to deploy into."
  type        = string
}

variable "region" {
  description = "Region for Cloud Run and Artifact Registry."
  type        = string
  default     = "us-central1"
}

variable "github_repository" {
  description = "owner/name of the repository that deploys the app."
  type        = string
}

variable "billing_account" {
  description = "Billing account ID for a budget alert, or null to skip it."
  type        = string
  default     = null
}

variable "domain" {
  description = "Optional custom domain on a Cloudflare zone, e.g. { zone = \"example.dev\", hostname = \"hello.example.dev\" }."
  type = object({
    zone     = string
    hostname = string
  })
  default = null
}
