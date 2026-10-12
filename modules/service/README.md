# service

One Cloud Run app:

- an Artifact Registry repository that keeps the latest `keep_images` images,
- a runtime service account (`<name>-run`) that can read only the secrets in `secrets`,
- the service, scaling from `min_instances` (default 0) to `max_instances`, public unless
  `public = false`, with an HTTP startup probe when `health_path` is set,
- optional `jobs` (`<name>-<key>`) on the same image, each with only the secrets it lists,
- a deploy service account (`<name>-deploy`) that only `github_repository` can use, allowed to
  push images and deploy this service and its jobs, nothing else.

Terraform ignores the image after the first apply: deploys set it. Inputs are described in
[variables.tf](variables.tf), outputs in [outputs.tf](outputs.tf).
