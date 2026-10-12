terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.27"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Keep state in a versioned bucket in real use:
  # backend "gcs" { bucket = "<project>-tfstate", prefix = "hello" }
}

provider "google" {
  project = var.project_id
  region  = var.region

  # Budgets are a billing-account API; bill its quota to this project.
  user_project_override = true
  billing_project       = var.project_id
}

# Reads CLOUDFLARE_API_TOKEN. Only used when var.domain is set.
provider "cloudflare" {}
