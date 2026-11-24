#!/usr/bin/env bash
# One-command deploy of the dev environment.
# Usage: ./scripts/deploy.sh            (plan + apply)
#        ./scripts/deploy.sh --destroy  (tear everything down)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_DIR="$ROOT/envs/dev"

if [[ ! -f "$ENV_DIR/backend.hcl" ]]; then
  echo "Missing envs/dev/backend.hcl - run the bootstrap step first (see README)." >&2
  exit 1
fi

cd "$ENV_DIR"
terraform init -input=false -backend-config=backend.hcl

if [[ "${1:-}" == "--destroy" ]]; then
  terraform destroy -auto-approve
  exit 0
fi

terraform fmt -check -recursive "$ROOT"
terraform validate
terraform plan -input=false -out=tfplan
terraform apply -input=false tfplan
rm -f tfplan

echo
echo "App URL: $(terraform output -raw app_url)"
echo "Instances need 2-3 minutes to pass ALB health checks."
