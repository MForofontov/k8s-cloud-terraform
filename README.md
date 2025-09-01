# k8s-cloud-terraform

[![Terraform Checks](https://github.com/MForofontov/k8s-cloud-terraform/actions/workflows/terraform.yml/badge.svg)](https://github.com/MForofontov/k8s-cloud-terraform/actions/workflows/terraform.yml)

A curated, multi-cloud Terraform infrastructure repository for Kubernetes clusters and supporting resources. This project includes modular code for AKS, EKS, GKE, IAM, networking, storage, and Kubernetes add-ons, designed for production-grade deployments across AWS, Azure, and GCP.

## Disclaimer
This infrastructure code provisions cloud resources that may incur costs and affect your cloud environment. **Review all modules and variables before applying. Use at your own risk.**

## Getting Started

### Clone the repository
```bash
git clone https://github.com/MForofontov/k8s-cloud-terraform.git
cd k8s-cloud-terraform
```

### Initialize and validate Terraform modules
```bash
terraform init
terraform validate
```

### Format all Terraform code
```bash
terraform fmt -recursive
```

### Run checks with GitHub Actions
Terraform format and validation are automatically run on pushes and pull requests via GitHub Actions.

## Directory Overview

### environments
Environment-specific configurations (e.g. `dev`, `prod`). Each contains its own `main.tf`, `variables.tf`, and `terraform.tfvars`.

### modules
Reusable infrastructure modules:
- **aks**: Azure Kubernetes Service
- **eks**: Amazon EKS
- **gke**: Google Kubernetes Engine
- **iam**: Cross-cloud identity and access management
- **networking**: VPC/VNet, subnets, firewall rules
- **storage**: Cloud storage resources
- **k8s-addons**: Helm-based Kubernetes add-ons (monitoring, ingress, etc.)

### scripts
Helper scripts for Terraform workflows and codebase maintenance (e.g. `apply.sh`, `plan.sh`, `init.sh`).

## Contributing
Contributions are welcome. Add new modules or scripts in the appropriate folder and include clear usage instructions in the README or script file.

## Authors

- [Mykyta Forofontov](https://github.com/MForofontov)

## License
This project is licensed under the terms of the [MIT License](LICENSE).