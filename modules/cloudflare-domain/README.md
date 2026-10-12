# cloudflare-domain

Serves a Cloud Run service at a custom hostname through a Cloudflare Worker
([worker/proxy.js](worker/proxy.js)) on the free plan. The Worker streams responses, sets
`client_ip_header` to the visitor's IP and `secret_header` to a random secret that it shares
with the service through Secret Manager.

Pass `proxy_secret_id` into the service module's `secrets` so the service can read it, and trust
the IP header only when the secret header matches. The zone must already be on Cloudflare, and
the Cloudflare provider needs a token that can edit Workers scripts and routes, and DNS. Inputs are described in
[variables.tf](variables.tf), outputs in [outputs.tf](outputs.tf).
