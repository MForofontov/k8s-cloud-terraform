#==============================================================================
# This file contains the input variables for the Terraform configuration
# This file is for setting variable values for your dev environment.
# If left empty, Terraform will use defaults from variables.tf or prompt you for values.
#==============================================================================

#==============================================================================
# Dev Environment - Input Variables
#==============================================================================

# GCP project ID for the dev environment
gcp_project_id = "my-gcp-project"

# GCP region for resources
gcp_region = "us-central1"

# Logical environment name (used for tagging and naming)
environment = "dev"

# Owner or team responsible for this environment
owner = "devops"
