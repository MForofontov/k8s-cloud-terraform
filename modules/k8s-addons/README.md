# Kubernetes Addons Module

This Terraform module simplifies the deployment of common Kubernetes addons across EKS, AKS, and GKE clusters. It provides a unified interface for managing essential components regardless of the underlying cloud provider.

## Supported Addons

| Addon | AWS (EKS) | Azure (AKS) | GCP (GKE) | Description |
|-------|-----------|-------------|-----------|-------------|
| **Metrics Server** | ✅ | ✅ | ✅ | Cluster metrics for HPA and kubectl top |
| **Cluster Autoscaler** | ✅ | ✅ | ✅ | Automatic node scaling based on workload |
| **External DNS** | ✅ | ✅ | ✅ | Automatic DNS record synchronization |
| **Cert Manager** | ✅ | ✅ | ✅ | Certificate management with Let's Encrypt |
| **AWS Load Balancer Controller** | ✅ | ❌ | ❌ | AWS ALB/NLB integration |
| **NGINX Ingress** | ✅ | ✅ | ✅ | General-purpose ingress controller |
| **Prometheus Stack** | ✅ | ✅ | ✅ | Monitoring and alerting |
| **Loki** | ✅ | ✅ | ✅ | Log aggregation |
| **Velero** | ✅ | ✅ | ✅ | Backup and disaster recovery |
| **CSI Snapshotter** | ✅ | ✅ | ✅ | Volume snapshots |
| **Calico** | ✅ | ✅ | ✅ | Network policy enforcement |
| **App Gateway Ingress** | ❌ | ✅ | ❌ | Azure Application Gateway integration |
| **GCP Ingress Controller** | ❌ | ❌ | ✅ | GCP Load Balancer integration |

## Usage

```hcl
module "kubernetes_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_type      = "eks"  # Options: eks, aks, gke
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Enable desired addons
  enable_metrics_server    = true
  enable_cluster_autoscaler = true
  enable_prometheus        = true
  enable_external_dns      = true
  enable_cert_manager      = true
  enable_ingress_nginx     = true

  # Addon-specific configurations
  external_dns = {
    domain_filters = ["example.com"]
    policy         = "sync"
  }

  cert_manager = {
    create_clusterissuer = true
    email_address        = "admin@example.com"
  }

  ingress_nginx = {
    service_type       = "LoadBalancer"
    enable_ssl         = true
    default_ssl_certificate = "default/wildcard-example-com"
  }

  # Tagging
  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |
| azurerm | >= 3.0.0 |
| google | >= 4.0.0 |
| kubernetes | >= 2.10.0 |
| helm | >= 2.5.0 |
| kubectl | >= 1.14.0 |

## Input Variables

### Core Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the Kubernetes cluster | string | n/a | yes |
| cluster_endpoint | Endpoint of the Kubernetes cluster | string | n/a | yes |
| cluster_type | Type of Kubernetes cluster (eks, aks, gke) | string | n/a | yes |
| oidc_provider_arn | ARN of the OIDC provider (for EKS) | string | null | no |
| enable_metrics_server | Enable Metrics Server | bool | true | no |
| enable_cluster_autoscaler | Enable Cluster Autoscaler | bool | true | no |
| enable_external_dns | Enable External DNS | bool | false | no |
| enable_cert_manager | Enable Cert Manager | bool | false | no |
| enable_ingress_nginx | Enable NGINX Ingress Controller | bool | false | no |
| enable_prometheus | Enable Prometheus Stack | bool | false | no |
| enable_loki | Enable Loki for log aggregation | bool | false | no |
| enable_velero | Enable Velero for backup and restore | bool | false | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

### Addon-Specific Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| external_dns | External DNS configuration | map(any) | {} | no |
| cert_manager | Cert Manager configuration | map(any) | {} | no |
| ingress_nginx | NGINX Ingress configuration | map(any) | {} | no |
| prometheus | Prometheus Stack configuration | map(any) | {} | no |
| loki | Loki configuration | map(any) | {} | no |
| velero | Velero configuration | map(any) | {} | no |

## Output Variables

| Name | Description |
|------|-------------|
| metrics_server_enabled | Whether Metrics Server is enabled |
| cluster_autoscaler_enabled | Whether Cluster Autoscaler is enabled |
| external_dns_enabled | Whether External DNS is enabled |
| cert_manager_enabled | Whether Cert Manager is enabled |
| ingress_nginx_enabled | Whether NGINX Ingress is enabled |
| ingress_class_name | Name of the default ingress class |
| prometheus_enabled | Whether Prometheus is enabled |
| prometheus_endpoint | Endpoint of the Prometheus service |
| grafana_endpoint | Endpoint of the Grafana service |

## Cloud-Specific Examples

### AWS EKS Example

```hcl
module "eks_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_type      = "eks"
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Enable AWS-specific addons
  enable_aws_load_balancer_controller = true
  
  # Common addons
  enable_metrics_server    = true
  enable_cluster_autoscaler = true
  enable_prometheus        = true
  
  # AWS-specific configurations
  aws_load_balancer_controller = {
    service_account_name = "aws-load-balancer-controller"
    region               = "us-west-2"
    vpc_id               = module.vpc.vpc_id
  }
  
  cluster_autoscaler = {
    service_account_name = "cluster-autoscaler"
    aws_region           = "us-west-2"
    expander             = "least-waste"
    scale_down_enabled   = true
  }
}
```

### Azure AKS Example

```hcl
module "aks_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"

  cluster_name     = module.aks.cluster_name
  cluster_endpoint = module.aks.cluster_endpoint
  cluster_type     = "aks"
  
  # Enable Azure-specific addons
  enable_app_gateway_ingress_controller = true
  
  # Common addons
  enable_metrics_server     = true
  enable_cluster_autoscaler = false  # AKS has built-in autoscaling
  enable_cert_manager       = true
  
  # Azure-specific configurations
  app_gateway_ingress_controller = {
    app_gateway_id      = azurerm_application_gateway.main.id
    app_gateway_name    = azurerm_application_gateway.main.name
    resource_group_name = azurerm_resource_group.main.name
  }
}
```

### GCP GKE Example

```hcl
module "gke_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"

  cluster_name     = module.gke.cluster_name
  cluster_endpoint = module.gke.cluster_endpoint
  cluster_type     = "gke"
  
  # Enable GCP-specific addons
  enable_gcp_ingress_controller = true
  
  # Common addons
  enable_metrics_server     = true
  enable_cluster_autoscaler = false  # GKE has built-in autoscaling
  enable_prometheus         = true
  enable_loki               = true
  
  # GCP-specific configurations
  gcp_ingress_controller = {
    gcp_project_id = "my-gcp-project"
  }
}
```

## Advanced Configurations

### Prometheus Stack with Custom Values

```hcl
module "kubernetes_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"
  
  # Basic cluster configuration
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_type      = "eks"
  
  # Enable Prometheus Stack
  enable_prometheus = true
  
  # Advanced Prometheus configuration
  prometheus = {
    namespace                 = "monitoring"
    create_namespace          = true
    alertmanager_enabled      = true
    grafana_enabled           = true
    node_exporter_enabled     = true
    kube_state_metrics_enabled = true
    
    retention                 = "7d"
    storage_class             = "gp2"
    storage_size              = "50Gi"
    
    grafana_admin_password    = var.grafana_admin_password
    
    alertmanager_config = {
      slack_api_url     = var.slack_webhook_url
      slack_channel     = "#alerts"
      pagerduty_url     = var.pagerduty_service_key
    }
    
    custom_values = {
      "grafana.service.type"               = "LoadBalancer"
      "prometheus.prometheusSpec.resources.limits.cpu" = "1000m"
      "prometheus.prometheusSpec.resources.limits.memory" = "2Gi"
      "prometheus.prometheusSpec.resources.requests.cpu" = "500m"
      "prometheus.prometheusSpec.resources.requests.memory" = "1Gi"
    }
  }
}
```

### External DNS with Multi-Provider Support

```hcl
module "kubernetes_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"
  
  # Basic cluster configuration
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_type      = "eks"
  oidc_provider_arn = module.eks.oidc_provider_arn
  
  # Enable External DNS
  enable_external_dns = true
  
  # Advanced External DNS configuration
  external_dns = {
    namespace        = "external-dns"
    create_namespace = true
    
    providers        = ["aws", "cloudflare"]
    aws_region       = "us-west-2"
    aws_zone_type    = "public"
    
    domain_filters   = ["example.com", "staging.example.com"]
    policy           = "sync"
    
    cloudflare_api_token = var.cloudflare_api_token
    
    txt_owner_id     = "external-dns-${module.eks.cluster_name}"
    txt_prefix       = "ext-dns-"
    
    interval         = "1m"
    sources          = ["service", "ingress"]
  }
}
```

### Cert Manager with Let's Encrypt

```hcl
module "kubernetes_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"
  
  # Basic cluster configuration
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_type      = "eks"
  
  # Enable Cert Manager
  enable_cert_manager = true
  
  # Advanced Cert Manager configuration
  cert_manager = {
    namespace        = "cert-manager"
    create_namespace = true
    
    create_clusterissuer = true
    clusterissuer_name   = "letsencrypt-prod"
    clusterissuer_server = "https://acme-v02.api.letsencrypt.org/directory"
    email_address        = "admin@example.com"
    
    use_dns01_solver     = true
    dns01_provider       = "route53"
    
    route53_region       = "us-west-2"
    route53_hosted_zone_id = "Z1234567890ABC"
    
    solver_service_account_name = "cert-manager-dns"
  }
}
```

### Velero Backup with Cloud Storage

```hcl
module "kubernetes_addons" {
  source = "github.com/your-organization/k8s-cloud-terraform//modules/k8s-addons"
  
  # Basic cluster configuration
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_type      = "eks"
  oidc_provider_arn = module.eks.oidc_provider_arn
  
  # Enable Velero
  enable_velero = true
  
  # Advanced Velero configuration
  velero = {
    namespace        = "velero"
    create_namespace = true
    
    provider         = "aws"
    aws_region       = "us-west-2"
    bucket_name      = "my-cluster-backups"
    
    schedule         = "0 1 * * *"  # Daily at 1 AM
    retention_period = "168h"       # 7 days
    
    include_namespaces = ["default", "kube-system", "monitoring"]
    exclude_resources  = ["Secret"]
    
    enable_snapshot_backups = true
    snapshot_volumes = true
    
    backup_security_group_ids = [module.vpc.default_security_group_id]
    backup_subnet_ids         = module.vpc.private_subnet_ids
  }
}
```

## License

This module is released under the MIT License.