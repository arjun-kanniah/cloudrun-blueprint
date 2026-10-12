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
  project_id        = "demo-project"
  github_repository = "octo/hello"
}

run "without_a_domain" {
  command = plan

  assert {
    condition     = length(module.domain) == 0
    error_message = "No domain should mean no Cloudflare resources."
  }
}

run "with_a_domain" {
  command = plan

  variables {
    domain = { zone = "example.dev", hostname = "hello.example.dev" }
  }

  assert {
    condition     = output.url == "https://hello.example.dev"
    error_message = "The custom domain should be the app's URL."
  }
}
