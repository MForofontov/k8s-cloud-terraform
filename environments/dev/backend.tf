terraform {
  backend "gcs" {
    bucket  = "my-terraform-state-bucket"
    prefix  = "dev/state"
    project = "my-gcp-project"
  }
}
