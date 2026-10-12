mock_provider "google" {}
mock_provider "random" {}
mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = {
      zone_id = "zone123"
      account = { id = "account123" }
    }
  }
}

variables {
  project_id = "demo-project"
  zone       = "example.dev"
  hostname   = "hello.example.dev"
  origin_url = "https://hello-abc123-ul.a.run.app"
  name       = "hello"
}

run "defaults" {
  command = plan

  assert {
    condition     = one([for b in cloudflare_workers_script.proxy.bindings : b.text if b.name == "ORIGIN_HOST"]) == "hello-abc123-ul.a.run.app"
    error_message = "The Worker should forward to the run.app host, without the scheme."
  }

  assert {
    condition     = google_secret_manager_secret.proxy.secret_id == "hello-proxy-secret" && cloudflare_workers_script.proxy.script_name == "hello-proxy"
    error_message = "The secret and Worker should be named after the app."
  }

  assert {
    condition     = cloudflare_workers_custom_domain.this.zone_id == "zone123" && cloudflare_workers_custom_domain.this.account_id == "account123"
    error_message = "The custom domain should be created in the zone's account."
  }

  assert {
    condition     = output.url == "https://hello.example.dev"
    error_message = "Unexpected URL."
  }
}

run "custom_headers_and_secret" {
  command = plan

  variables {
    secret_id        = "proxy-secret"
    client_ip_header = "x-app-client-ip"
    secret_header    = "x-app-proxy-secret"
  }

  assert {
    condition     = google_secret_manager_secret.proxy.secret_id == "proxy-secret"
    error_message = "secret_id should override the secret's name."
  }

  assert {
    condition = (
      one([for b in cloudflare_workers_script.proxy.bindings : b.text if b.name == "CLIENT_IP_HEADER"]) == "x-app-client-ip"
      && one([for b in cloudflare_workers_script.proxy.bindings : b.text if b.name == "SECRET_HEADER"]) == "x-app-proxy-secret"
    )
    error_message = "Header names should reach the Worker."
  }
}
