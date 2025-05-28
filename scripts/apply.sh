#!/usr/bin/env bash

#==============================================================================
# Terraform Apply Script
#
# This script runs 'terraform apply' for the selected environment, applying
# the planned infrastructure changes.
#==============================================================================

set -e

ENV_DIR=${1:-"environments/dev"}

echo "Running Terraform apply in $ENV_DIR ..."

cd "$(dirname "$0")/../$ENV_DIR"

terraform apply

echo "Terraform apply complete for $ENV_DIR."