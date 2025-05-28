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