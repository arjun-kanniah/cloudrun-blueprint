# cloudrun-blueprint task runner. Run `just` to list recipes.

dirs := "modules/project modules/service modules/cloudflare-domain examples/hello"

_default:
    @just --list

# Format all Terraform files
fmt:
    terraform fmt -recursive

# Everything CI runs: format check, then validate and test each module and the example
check:
    #!/usr/bin/env bash
    set -euo pipefail
    terraform fmt -check -recursive
    for dir in {{dirs}}; do
        echo "== $dir"
        terraform -chdir="$dir" init -backend=false -input=false >/dev/null
        terraform -chdir="$dir" validate
        terraform -chdir="$dir" test
    done
