#!/usr/bin/env bash
# Wrapper for OpenTofu that sets up the R2 state backend credentials.
# Provider variables (Cloudflare, Render) come from terraform.tfvars.
#
# Usage: ./infrastructure/tofu.sh plan                   # production
#        ./infrastructure/tofu.sh apply                  # production
#        TOFU_ENV=staging ./infrastructure/tofu.sh plan   # staging

set -euo pipefail

# Load .env from project root (contains R2 credentials for state backend)
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Map R2 credentials to AWS env vars (S3-compatible state backend)
export AWS_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY}"
export AWS_ENDPOINT_URL_S3="${R2_ENDPOINT}"

# Run tofu in the target environment
ENV="${TOFU_ENV:-production}"
cd "$(dirname "$0")/environments/${ENV}"
tofu "$@"
