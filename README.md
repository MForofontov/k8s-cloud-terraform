# Kubernetes Cloud Terraform

This repository contains Terraform configurations and reusable modules for provisioning Kubernetes clusters and supporting infrastructure across multiple cloud providers. Example environments are provided under `environments/`.

## Prerequisites

- **Terraform**: Install [Terraform](https://developer.hashicorp.com/terraform/downloads) 1.x on your workstation.
- **Cloud credentials**: Configure credentials for the cloud provider you plan to use (e.g. AWS, Azure, or GCP) so Terraform can authenticate.

## Getting Started (Dev Environment)

1. **Initialize** the Terraform working directory:
   ```bash
   ./scripts/init.sh
   ```
   By default this initializes the `environments/dev` configuration.
2. **Review the plan** of changes Terraform will make:
   ```bash
   ./scripts/plan.sh
   ```
   This script runs `terraform plan -input=false` so it won't prompt for
   variable values interactively.
3. **Apply** the configuration to create resources:
   ```bash
   ./scripts/apply.sh
   ```
   The apply script uses `terraform apply -auto-approve -input=false` to
   skip the confirmation prompt during automated runs.

Variables for the dev environment can be adjusted in `environments/dev/terraform.tfvars`.

## Module Structure

- `modules/aks` – Azure Kubernetes Service cluster module.
- `modules/eks` – Amazon EKS cluster module.
- `modules/gke` – Google Kubernetes Engine cluster module.
- `modules/networking` – Networking and VPC resources.
- `modules/storage` – Cloud storage (buckets, etc.).
- `modules/iam` – IAM roles and policies.
- `modules/k8s-addons` – Common Kubernetes addons.

Each environment directory (for example `environments/dev`) composes these modules to build a full cluster.
