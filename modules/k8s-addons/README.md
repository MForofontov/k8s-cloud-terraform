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
| kubernetes_config_path | Path to the Kubernetes config file | string | null | no |
| kubernetes_config_context | Kubernetes config context to use | string | null | no |
| cluster_context | Cluster context information for smart defaults | object({cloud_provider = string, cluster_size = string, region = string, environment = string, is_production = bool}) | {cloud_provider = "aws", cluster_size = "medium", region = "us-west-2", environment = "dev", is_production = false} | no |
| storage_class | Default storage class to use for persistent volumes | string | null | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

### Feature Toggles

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_metrics_server | Enable Metrics Server | bool | false | no |
| enable_cluster_autoscaler | Enable Cluster Autoscaler | bool | false | no |
| enable_karpenter | Enable Karpenter autoscaler | bool | false | no |
| enable_nginx_ingress | Enable NGINX Ingress Controller | bool | false | no |
| enable_cert_manager | Enable Cert Manager | bool | false | no |
| enable_external_dns | Enable External DNS | bool | false | no |
| enable_prometheus_stack | Enable Prometheus Stack | bool | false | no |
| enable_fluent_bit | Enable Fluent Bit for log forwarding | bool | false | no |
| enable_argocd | Enable ArgoCD GitOps controller | bool | false | no |
| enable_velero | Enable Velero for backup and restore | bool | false | no |
| enable_sealed_secrets | Enable Sealed Secrets for secret management | bool | false | no |
| enable_istio | Enable Istio service mesh | bool | false | no |
| enable_kyverno | Enable Kyverno policy engine | bool | false | no |
| enable_crossplane | Enable Crossplane for infrastructure provisioning | bool | false | no |
| enable_calico | Enable Calico for network policies | bool | false | no |
| enable_csi_snapshotter | Enable CSI Snapshotter for volume snapshots | bool | false | no |
| enable_aws_load_balancer_controller | Enable AWS Load Balancer Controller | bool | false | no |
| enable_app_gateway_ingress_controller | Enable Azure Application Gateway Ingress Controller | bool | false | no |
| enable_gcp_ingress_controller | Enable GCP Ingress Controller | bool | false | no |

### Metrics Server Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| metrics_server.name | Name of the Helm release | string | "metrics-server" | no |
| metrics_server.chart | Name of the Helm chart | string | "metrics-server" | no |
| metrics_server.repository | Helm chart repository URL | string | "https://kubernetes-sigs.github.io/metrics-server/" | no |
| metrics_server.chart_version | Version of the Helm chart | string | null | no |
| metrics_server.namespace | Kubernetes namespace for deployment | string | "kube-system" | no |
| metrics_server.create_namespace | Whether to create the namespace | bool | false | no |
| metrics_server.values | Path to values file | string | "" | no |
| metrics_server.set_values | Map of values for Helm chart | map(any) | {} | no |
| metrics_server.set | Map of individual values for Helm chart | map(string) | {} | no |

### Cluster Autoscaler Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_autoscaler.name | Name of the Helm release | string | "cluster-autoscaler" | no |
| cluster_autoscaler.chart | Name of the Helm chart | string | "cluster-autoscaler" | no |
| cluster_autoscaler.repository | Helm chart repository URL | string | "https://kubernetes.github.io/autoscaler" | no |
| cluster_autoscaler.chart_version | Version of the Helm chart | string | null | no |
| cluster_autoscaler.namespace | Kubernetes namespace for deployment | string | "kube-system" | no |
| cluster_autoscaler.create_namespace | Whether to create the namespace | bool | false | no |
| cluster_autoscaler.aws_config.auto_discovery | Use AWS auto-discovery | bool | true | no |
| cluster_autoscaler.aws_config.cluster_name | EKS cluster name | string | null | no |
| cluster_autoscaler.aws_config.region | AWS region | string | null | no |
| cluster_autoscaler.aws_config.role_arn | IAM role ARN for Cluster Autoscaler | string | null | no |
| cluster_autoscaler.aws_config.expander | Node group expansion strategy | string | "least-waste" | no |
| cluster_autoscaler.azure_config.node_resource_group | Azure node resource group | string | null | no |
| cluster_autoscaler.gcp_config.project_id | GCP project ID | string | null | no |
| cluster_autoscaler.gcp_config.location | GCP location | string | null | no |
| cluster_autoscaler.gcp_config.cluster_name | GKE cluster name | string | null | no |
| cluster_autoscaler.gcp_config.node_pool_patterns | Node pool name patterns to match | list(string) | [".*"] | no |

### Karpenter Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| karpenter.name | Name of the Helm release | string | "karpenter" | no |
| karpenter.chart | Name of the Helm chart | string | "karpenter" | no |
| karpenter.repository | Helm chart repository URL | string | "https://charts.karpenter.sh" | no |
| karpenter.chart_version | Version of the Helm chart | string | null | no |
| karpenter.namespace | Kubernetes namespace for deployment | string | "karpenter" | no |
| karpenter.create_namespace | Whether to create the namespace | bool | true | no |
| karpenter.aws_config.cluster_name | EKS cluster name | string | null | no |
| karpenter.aws_config.cluster_endpoint | EKS cluster endpoint | string | null | no |
| karpenter.aws_config.instance_profile | AWS instance profile name | string | null | no |
| karpenter.provisioner.create_default | Create a default provisioner | bool | true | no |
| karpenter.provisioner.default_name | Name for the default provisioner | string | "default" | no |

### NGINX Ingress Controller Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| nginx_ingress.name | Name of the Helm release | string | "nginx-ingress" | no |
| nginx_ingress.chart | Name of the Helm chart | string | "ingress-nginx" | no |
| nginx_ingress.repository | Helm chart repository URL | string | "https://kubernetes.github.io/ingress-nginx" | no |
| nginx_ingress.chart_version | Version of the Helm chart | string | null | no |
| nginx_ingress.namespace | Kubernetes namespace for deployment | string | "ingress-nginx" | no |
| nginx_ingress.create_namespace | Whether to create the namespace | bool | true | no |
| nginx_ingress.controller.replicas | Number of controller replicas | number | null | no |
| nginx_ingress.controller.service_type | Type of Kubernetes service | string | "LoadBalancer" | no |
| nginx_ingress.controller.use_proxy_protocol | Whether to use proxy protocol | bool | false | no |
| nginx_ingress.controller.use_host_port | Whether to use host ports | bool | false | no |
| nginx_ingress.controller.publish_service | Whether to publish service | bool | true | no |
| nginx_ingress.controller.internal | Whether to create an internal load balancer | bool | false | no |

### Cert Manager Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cert_manager.name | Name of the Helm release | string | "cert-manager" | no |
| cert_manager.chart | Name of the Helm chart | string | "cert-manager" | no |
| cert_manager.repository | Helm chart repository URL | string | "https://charts.jetstack.io" | no |
| cert_manager.chart_version | Version of the Helm chart | string | null | no |
| cert_manager.namespace | Kubernetes namespace for deployment | string | "cert-manager" | no |
| cert_manager.create_namespace | Whether to create the namespace | bool | true | no |
| cert_manager.create_clusterissuer | Whether to create a ClusterIssuer | bool | false | no |
| cert_manager.issuer_type | Type of issuer to create | string | "letsencrypt-prod" | no |
| cert_manager.email_address | Email address for Let's Encrypt | string | null | no |

### External DNS Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| external_dns.name | Name of the Helm release | string | "external-dns" | no |
| external_dns.chart | Name of the Helm chart | string | "external-dns" | no |
| external_dns.repository | Helm chart repository URL | string | "https://kubernetes-sigs.github.io/external-dns/" | no |
| external_dns.chart_version | Version of the Helm chart | string | null | no |
| external_dns.namespace | Kubernetes namespace for deployment | string | "external-dns" | no |
| external_dns.create_namespace | Whether to create the namespace | bool | true | no |
| external_dns.provider_config.provider | DNS provider | string | null | no |
| external_dns.provider_config.domain_filters | List of domain filters | list(string) | [] | no |
| external_dns.provider_config.exclude_domains | List of domains to exclude | list(string) | [] | no |
| external_dns.provider_config.txt_owner_id | TXT record owner ID | string | null | no |
| external_dns.provider_config.txt_prefix | TXT record prefix | string | null | no |
| external_dns.provider_config.registry | Registry method | string | "txt" | no |
| external_dns.provider_config.policy | DNS record reconciliation policy | string | "upsert-only" | no |

### Prometheus Stack Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| prometheus_stack.name | Name of the Helm release | string | "prometheus" | no |
| prometheus_stack.chart | Name of the Helm chart | string | "kube-prometheus-stack" | no |
| prometheus_stack.repository | Helm chart repository URL | string | "https://prometheus-community.github.io/helm-charts" | no |
| prometheus_stack.chart_version | Version of the Helm chart | string | null | no |
| prometheus_stack.namespace | Kubernetes namespace for deployment | string | "monitoring" | no |
| prometheus_stack.create_namespace | Whether to create the namespace | bool | true | no |
| prometheus_stack.prometheus.retention | Data retention period | string | "10d" | no |
| prometheus_stack.prometheus.scrape_interval | Scrape interval | string | "30s" | no |
| prometheus_stack.prometheus.evaluation_interval | Evaluation interval | string | "30s" | no |
| prometheus_stack.prometheus.enable_remote_write | Enable remote write | bool | false | no |
| prometheus_stack.prometheus.remote_write_urls | Remote write URLs | list(string) | [] | no |
| prometheus_stack.prometheus.storage.size | Storage size | string | "50Gi" | no |
| prometheus_stack.prometheus.storage.storage_class | Storage class | string | null | no |
| prometheus_stack.alertmanager.enabled | Enable Alertmanager | bool | true | no |
| prometheus_stack.alertmanager.replicas | Alertmanager replicas | number | null | no |
| prometheus_stack.alertmanager.retention | Alertmanager retention | string | "120h" | no |
| prometheus_stack.grafana.enabled | Enable Grafana | bool | true | no |
| prometheus_stack.grafana.admin_password | Grafana admin password | string | "prom-operator" | no |
| prometheus_stack.grafana.admin_user | Grafana admin username | string | "admin" | no |

### AWS Load Balancer Controller Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_load_balancer_controller.name | Name of the Helm release | string | "aws-load-balancer-controller" | no |
| aws_load_balancer_controller.chart | Name of the Helm chart | string | "aws-load-balancer-controller" | no |
| aws_load_balancer_controller.repository | Helm chart repository URL | string | "https://aws.github.io/eks-charts" | no |
| aws_load_balancer_controller.chart_version | Version of the Helm chart | string | null | no |
| aws_load_balancer_controller.namespace | Kubernetes namespace for deployment | string | "kube-system" | no |
| aws_load_balancer_controller.create_namespace | Whether to create the namespace | bool | false | no |
| aws_load_balancer_controller.aws_config.cluster_name | EKS cluster name | string | null | no |
| aws_load_balancer_controller.aws_config.region | AWS region | string | null | no |
| aws_load_balancer_controller.aws_config.vpc_id | VPC ID | string | null | no |
| aws_load_balancer_controller.controller_config.enable_shield | Enable AWS Shield | bool | false | no |
| aws_load_balancer_controller.controller_config.enable_waf | Enable AWS WAF | bool | false | no |
| aws_load_balancer_controller.controller_config.ingress_class | Ingress class name | string | "alb" | no |

## Output Variables

### Common Outputs

| Name | Description | Type |
|------|-------------|------|
| installed_addons | Map of all installed addons with their status | map(map(string)) |
| installed_addon_names | List of enabled addon names | list(string) |
| addons_health | Consolidated health status of all installed addons | object({all_healthy = bool, addon_status = map(string)}) |

### Metrics Server Outputs

| Name | Description | Type |
|------|-------------|------|
| metrics_server_enabled | Whether Metrics Server is enabled | bool |
| metrics_server_namespace | Namespace where Metrics Server is deployed | string |
| metrics_server_version | Version of Metrics Server deployed | string |

### Cluster Autoscaler Outputs

| Name | Description | Type |
|------|-------------|------|
| cluster_autoscaler_enabled | Whether Cluster Autoscaler is enabled | bool |
| cluster_autoscaler_namespace | Namespace where Cluster Autoscaler is deployed | string |
| cluster_autoscaler_version | Version of Cluster Autoscaler deployed | string |

### Karpenter Outputs

| Name | Description | Type |
|------|-------------|------|
| karpenter_enabled | Whether Karpenter is enabled | bool |
| karpenter_namespace | Namespace where Karpenter is deployed | string |
| karpenter_version | Version of Karpenter deployed | string |

## NGINX Ingress Outputs

| Name | Description | Type |
|------|-------------|------|
| nginx_ingress_enabled | Whether NGINX Ingress is enabled | bool |
| nginx_ingress_namespace | Namespace where NGINX Ingress is deployed | string |
| nginx_ingress_version | Version of NGINX Ingress deployed | string |
| ingress_class_name | Name of the default ingress class | string |

## Cert Manager Outputs

| Name | Description | Type |
|------|-------------|------|
| cert_manager_enabled | Whether Cert Manager is enabled | bool |
| cert_manager_namespace | Namespace where Cert Manager is deployed | string |
| cert_manager_version | Version of Cert Manager deployed | string |
| cert_manager_issuers | List of ClusterIssuers created | list(string) |

### External DNS Outputs

| Name | Description | Type |
|------|-------------|------|
| external_dns_enabled | Whether External DNS is enabled | bool |
| external_dns_namespace | Namespace where External DNS is deployed | string |
| external_dns_version | Version of External DNS deployed | string |

### Prometheus Stack Outputs

| Name | Description | Type |
|------|-------------|------|
| prometheus_stack_enabled | Whether Prometheus Stack is enabled | bool |
| prometheus_stack_namespace | Namespace where Prometheus Stack is deployed | string |
| prometheus_stack_version | Version of Prometheus Stack deployed | string |
| prometheus_endpoint | Endpoint of the Prometheus service | string |
| grafana_endpoint | Endpoint of the Grafana service | string |

### AWS Load Balancer Controller Outputs

| Name | Description | Type |
|------|-------------|------|
| aws_load_balancer_controller_enabled | Whether AWS Load Balancer Controller is enabled | bool |
| aws_load_balancer_controller_namespace | Namespace where AWS Load Balancer Controller is deployed | string |
| aws_load_balancer_controller_version | Version of AWS Load Balancer Controller deployed | string |

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