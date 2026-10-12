variable "project_id" {
  description = "Google Cloud project that holds the proxy secret."
  type        = string
}

variable "zone" {
  description = "Cloudflare zone (domain) that hostname belongs to. Add the zone in the Cloudflare dashboard first: moving nameservers is a manual step at the registrar."
  type        = string
}

variable "hostname" {
  description = "Custom domain for the service, e.g. app.example.dev."
  type        = string
}

variable "origin_url" {
  description = "The Cloud Run service's URL (the service module's uri)."
  type        = string
}

variable "name" {
  description = "Names the Worker (<name>-proxy) and the proxy secret (<name>-proxy-secret)."
  type        = string
}

variable "secret_id" {
  description = "Override the proxy secret's ID, e.g. to keep an existing secret."
  type        = string
  default     = null
}

variable "client_ip_header" {
  description = "Header that carries the visitor's IP to the service."
  type        = string
  default     = "x-client-ip"
}

variable "secret_header" {
  description = "Header that carries the shared secret. The service should trust client_ip_header only when this matches."
  type        = string
  default     = "x-proxy-secret"
}

variable "compatibility_date" {
  description = "Workers runtime compatibility date."
  type        = string
  default     = "2026-09-01"
}
