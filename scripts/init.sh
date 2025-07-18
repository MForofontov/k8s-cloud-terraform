#!/usr/bin/env bash

#==============================================================================
# Terraform Project Initialization Script
#
# This script initializes the Terraform working directory, downloads providers,
# and prepares the backend for the selected environment.
#==============================================================================

set -euo pipefail

ENV_DIR=${1:-"environments/dev"}

echo "Initializing Terraform in $ENV_DIR ..."

cd "$(dirname "$0")/../$ENV_DIR"

terraform init -input=false

echo "Terraform initialization complete for $ENV_DIR."
