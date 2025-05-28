#==============================================================================
# This file defines input variables for the dev environment. These variables
# allow you to customize project, region, naming, and ownership for resources
# provisioned in this environment. Adjust defaults as needed for your team.
#==============================================================================

#==============================================================================
# Dev Environment - Input Variables
#==============================================================================

variable "gcp_project_id" {
  description = "The GCP project ID for the dev environment."
  type        = string
  default     = "my-gcp-project"
}

variable "gcp_region" {
  description = "The GCP region for the dev environment."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "The owner or team responsible for this environment."
  type        = string
  default     = "devops"
}