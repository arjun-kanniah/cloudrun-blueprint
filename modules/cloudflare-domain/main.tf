# A custom domain for a Cloud Run service through a Cloudflare Worker on the free plan.
#
# Why a Worker: Cloud Run domain mapping is in preview and only in some regions, a global load
# balancer costs about USD 18 a month, and Firebase Hosting buffers responses, which breaks
# streaming (server-sent events). Workers stream response bodies through as they arrive.
#
# Requests reach Cloud Run from Cloudflare's addresses, so the Worker passes the visitor's IP in
# a header, with a secret shared with the service so a direct caller can't forge it.

data "cloudflare_zone" "this" {
  filter = { name = var.zone }
}

resource "random_password" "proxy_secret" {
  length  = 40
  special = false
}

resource "google_secret_manager_secret" "proxy" {
  project   = var.project_id
  secret_id = coalesce(var.secret_id, "${var.name}-proxy-secret")
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "proxy" {
  secret      = google_secret_manager_secret.proxy.id
  secret_data = random_password.proxy_secret.result
}

resource "cloudflare_workers_script" "proxy" {
  account_id         = data.cloudflare_zone.this.account.id
  script_name        = "${var.name}-proxy"
  content            = file("${path.module}/worker/proxy.js")
  main_module        = "proxy.js"
  compatibility_date = var.compatibility_date

  bindings = [
    {
      name = "ORIGIN_HOST"
      type = "plain_text"
      text = trimprefix(var.origin_url, "https://")
    },
    {
      name = "CLIENT_IP_HEADER"
      type = "plain_text"
      text = var.client_ip_header
    },
    {
      name = "SECRET_HEADER"
      type = "plain_text"
      text = var.secret_header
    },
    {
      name = "PROXY_SECRET"
      type = "secret_text"
      text = random_password.proxy_secret.result
    },
  ]
}

# Creates the DNS record and certificate for the hostname and routes it to the Worker.
resource "cloudflare_workers_custom_domain" "this" {
  account_id = data.cloudflare_zone.this.account.id
  zone_id    = data.cloudflare_zone.this.zone_id
  hostname   = var.hostname
  service    = cloudflare_workers_script.proxy.script_name
}
