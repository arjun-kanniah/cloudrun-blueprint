variable "project_id" {
  description = "Google Cloud project to deploy into."
  type        = string
}

variable "region" {
  description = "Region for the service, its jobs and its image repository."
  type        = string
}

variable "name" {
  description = "Service name. Also names the image repository, the service accounts (<name>-run, <name>-deploy) and the jobs (<name>-<job>)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,22}$", var.name))
    error_message = "Use 5–23 lowercase letters, digits or hyphens, starting with a letter, so the service account IDs fit."
  }
}

variable "display_name" {
  description = "Human-readable name used in descriptions. Defaults to name."
  type        = string
  default     = null
}

variable "github_repository" {
  description = "owner/name of the repository whose GitHub Actions deploy this service."
  type        = string
}

variable "workload_identity_pool_name" {
  description = "Full name of the GitHub identity pool (the project module's workload_identity_pool_name)."
  type        = string
}

variable "env" {
  description = "Plain environment variables for the service."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variable => Secret Manager secret ID. The runtime account may read these secrets and nothing else. Create the secrets and their values outside Terraform so values stay out of state."
  type        = map(string)
  default     = {}
}

variable "public" {
  description = "Allow unauthenticated requests. Set false for a private service or one that only a proxy calls."
  type        = bool
  default     = true
}

variable "cpu" {
  description = "CPU limit per instance."
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory limit per instance."
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Instances kept warm. 0 scales to zero: no cost when idle, with a cold start on the first request."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Hard ceiling on instances, and so on cost."
  type        = number
  default     = 2
}

variable "concurrency" {
  description = "Requests each instance handles at once."
  type        = number
  default     = 80
}

variable "timeout" {
  description = "Request timeout. Streaming responses must finish within it."
  type        = string
  default     = "300s"
}

variable "health_path" {
  description = "HTTP path for the startup probe, or null for Cloud Run's default TCP probe."
  type        = string
  default     = null
}

variable "jobs" {
  description = <<-EOT
    Cloud Run jobs that share the service's image, such as database migrations, keyed by a short
    name (the job is named <name>-<key>). secret_env lists environment variables from `secrets`
    that the job receives. Deploys update a job's image and can run it before the new revision.
  EOT
  type = map(object({
    command     = optional(list(string))
    args        = optional(list(string))
    env         = optional(map(string), {})
    secret_env  = optional(list(string), [])
    cpu         = optional(string, "1")
    memory      = optional(string, "512Mi")
    timeout     = optional(string, "600s")
    max_retries = optional(number, 1)
  }))
  default = {}

  validation {
    condition     = alltrue(flatten([for j in values(var.jobs) : [for e in j.secret_env : contains(keys(var.secrets), e)]]))
    error_message = "Each job's secret_env entries must be keys of var.secrets."
  }
}

variable "keep_images" {
  description = "Most recent images to keep in the repository; older ones are deleted after a day. Keeps storage within the free tier."
  type        = number
  default     = 3
}
