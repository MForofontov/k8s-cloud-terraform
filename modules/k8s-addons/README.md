# Kubernetes Addons Module

This Terraform module installs and configures essential add-ons for Kubernetes clusters across multiple cloud providers (AWS EKS, Azure AKS, Google GKE). It provides a unified interface for deploying common operational components that extend core Kubernetes functionality.

## Features

- **Cross-Cloud Compatible**: Works with EKS, AKS, and GKE clusters
- **Modular Design**: Enable only the add-ons you need
- **Secure Defaults**: Pre-configured with security best practices
- **Customizable**: Extensive configuration options for each add-on
- **Version Control**: Explicit versioning for all components

## Supported Add-ons

| Add-on | Description | Default Version |
|--------|-------------|-----------------|
| **Metrics Server** | Cluster-wide resource metrics for Horizontal Pod Autoscaling | v0.6.3 |
| **Cluster Autoscaler** | Automatically adjusts cluster size based on resource demand | v1.27.3 |
| **NGINX Ingress Controller** | Advanced HTTP/HTTPS traffic routing and load balancing | v1.8.1 |
| **Cert Manager** | Automated certificate management from multiple issuers | v1.12.3 |
| **External DNS** | Synchronizes Kubernetes Ingress/Services with external DNS providers | v0.13.5 |
| **Prometheus & Grafana** | Comprehensive monitoring and visualization stack | v45.28.0 |
| **Velero** | Backup and disaster recovery for cluster resources | v1.11.1 |
| **Fluentd/Fluent Bit** | Log collection and forwarding | v0.36.0 |
| **Kyverno** | Kubernetes Policy Management | v1.10.0 |
| **Sealed Secrets** | Manage encrypted secrets in Git | v0.23.1 |

## Usage

```hcl
module "k8s_addons" {
  source = "github.com/your-org/k8s-cloud-terraform/modules/k8s-addons"

  cluster_name      = "production-cluster"
  cluster_type      = "eks"  # One of: eks, aks, gke
  cluster_endpoint  = module.eks.cluster_endpoint
  kubeconfig_path   = module.eks.kubeconfig_path
  
  # Enable and configure specific addons
  enable_metrics_server     = true
  enable_cluster_autoscaler = true
  enable_nginx_ingress      = true
  
  nginx_ingress_config = {
    service_type = "LoadBalancer"
    replicas     = 2
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }
  
  enable_cert_manager = true
  cert_manager_config = {
    create_cluster_issuer = true
    cluster_issuer_email  = "admin@example.com"
    cluster_issuer_type   = "letsencrypt-prod"
  }
  
  # Additional add-on configurations...
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| kubernetes | >= 2.16.0 |
| helm | >= 2.8.0 |
| kubectl | >= 1.14.0 |

## Cloud Provider Support

| Provider | Support Level | Notes |
|----------|--------------|-------|
| AWS EKS | Full | All features supported |
| Azure AKS | Full | All features supported |
| Google GKE | Full | All features supported |

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the Kubernetes cluster | `string` | n/a | yes |
| cluster_type | Type of Kubernetes cluster (eks, aks, gke) | `string` | n/a | yes |
| cluster_endpoint | Endpoint URL of the Kubernetes cluster | `string` | n/a | yes |
| kubeconfig_path | Path to kubeconfig file for cluster access | `string` | n/a | yes |
| enable_metrics_server | Enable Metrics Server add-on | `bool` | `false` | no |
| enable_cluster_autoscaler | Enable Cluster Autoscaler add-on | `bool` | `false` | no |
| enable_nginx_ingress | Enable NGINX Ingress Controller add-on | `bool` | `false` | no |
| enable_cert_manager | Enable Cert Manager add-on | `bool` | `false` | no |
| enable_external_dns | Enable External DNS add-on | `bool` | `false` | no |
| enable_prometheus | Enable Prometheus & Grafana add-on | `bool` | `false` | no |
| enable_velero | Enable Velero add-on | `bool` | `false` | no |
| enable_fluentbit | Enable Fluent Bit add-on | `bool` | `false` | no |
| enable_kyverno | Enable Kyverno add-on | `bool` | `false` | no |
| enable_sealed_secrets | Enable Sealed Secrets add-on | `bool` | `false` | no |
| tags | Tags to apply to supported resources | `map(string)` | `{}` | no |

## Output Variables

| Name | Description |
|------|-------------|
| metrics_server_status | Status of the Metrics Server deployment |
| nginx_ingress_endpoint | Load balancer endpoint for the NGINX Ingress Controller |
| cert_manager_status | Status of the Cert Manager deployment |
| prometheus_grafana_endpoint | Endpoint for accessing Grafana UI |
| installed_addons | Map of all installed add-ons with their status and version |

## Provider-Specific Examples

### AWS EKS Example

```hcl
module "eks_addons" {
  source = "github.com/your-org/k8s-cloud-terraform/modules/k8s-addons"

  cluster_name      = module.eks.cluster_name
  cluster_type      = "eks"
  cluster_endpoint  = module.eks.cluster_endpoint
  kubeconfig_path   = module.eks.kubeconfig_path
  
  enable_cluster_autoscaler = true
  cluster_autoscaler_config = {
    auto_discovery = {
      enabled      = true
      cluster_name = module.eks.cluster_name
    }
    aws_region     = "us-west-2"
  }
  
  enable_external_dns = true
  external_dns_config = {
    provider       = "aws"
    domain_filters = ["example.com"]
    aws_zone_type  = "public"
  }
  
  tags = {
    Environment = "production"
    CostCenter  = "cloud-ops"
  }
}
```

### Azure AKS Example

```hcl
module "aks_addons" {
  source = "github.com/your-org/k8s-cloud-terraform/modules/k8s-addons"

  cluster_name      = module.aks.name
  cluster_type      = "aks"
  cluster_endpoint  = module.aks.host
  kubeconfig_path   = module.aks.kubeconfig_path
  
  enable_nginx_ingress = true
  nginx_ingress_config = {
    service_type = "LoadBalancer"
    replicas     = 2
    additional_set = {
      "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal" = "true"
    }
  }
  
  enable_cert_manager = true
  cert_manager_config = {
    create_cluster_issuer = true
    cluster_issuer_email  = "admin@example.com"
  }
  
  tags = {
    Environment = "production"
    Department  = "engineering"
  }
}
```

### Google GKE Example

```hcl
module "gke_addons" {
  source = "github.com/your-org/k8s-cloud-terraform/modules/k8s-addons"

  cluster_name      = module.gke.name
  cluster_type      = "gke"
  cluster_endpoint  = module.gke.endpoint
  kubeconfig_path   = module.gke.kubeconfig_path
  
  enable_prometheus = true
  prometheus_config = {
    storage_class = "standard"
    storage_size  = "100Gi"
    grafana = {
      enabled        = true
      admin_password = data.google_secret_manager_secret_version.grafana_password.secret_data
      ingress = {
        enabled     = true
        host        = "grafana.example.com"
      }
    }
  }
  
  enable_external_dns = true
  external_dns_config = {
    provider       = "google"
    domain_filters = ["example.com"]
  }
}
```

## License

This module is released under the MIT License.