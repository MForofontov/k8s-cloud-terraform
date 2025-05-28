#!/usr/bin/env bash

#==============================================================================
# Terraform Plan Script
#
# This script runs 'terraform plan' for the selected environment, showing
# the changes Terraform will make without applying them.
#==============================================================================

set -euo pipefail

ENV_DIR=${1:-"environments/dev"}

echo "Running Terraform plan in $ENV_DIR ..."

cd "$(dirname "$0")/../$ENV_DIR"

terraform init -input=false

terraform plan

echo "Terraform plan complete for $ENV_DIR."