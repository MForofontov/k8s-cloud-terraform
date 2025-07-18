#!/usr/bin/env bash

#==============================================================================
# Terraform Apply Script
#
# This script initializes the working directory (if needed) and runs
# 'terraform apply' for the selected environment, applying the planned
# infrastructure changes.
#==============================================================================

set -euo pipefail

ENV_DIR=${1:-"environments/dev"}

echo "Running Terraform apply in $ENV_DIR ..."

cd "$(dirname "$0")/../$ENV_DIR"

terraform init -input=false

terraform apply -auto-approve -input=false

echo "Terraform apply complete for $ENV_DIR."
