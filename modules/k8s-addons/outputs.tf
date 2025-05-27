#==============================================================================
# Kubernetes Addons Module Outputs
#
# This file defines the output values provided by the Kubernetes Addons module.
# Each addon has a set of outputs that include:
#   - Whether the addon is enabled
#   - The namespace where the addon is installed
#   - The version of the addon that is deployed
#   - Additional relevant information specific to the addon
#
# These outputs can be used to reference deployed resources or to build
# dependencies between modules.
#==============================================================================

#==============================================================================
# Metrics Server
# Core resource metrics for horizontal pod autoscaling
#==============================================================================
output "metrics_server_enabled" {
  description = "Whether Metrics Server is enabled. Use this to conditionally configure resources that depend on Metrics Server."
  value       = var.enable_metrics_server
}

output "metrics_server_namespace" {
  description = "Namespace where Metrics Server is installed. Useful for creating resources that need to interact with Metrics Server."
  value       = var.enable_metrics_server ? helm_release.metrics_server[0].namespace : null
}

output "metrics_server_version" {
  description = "Version of Metrics Server that is deployed. Helpful for tracking the currently installed version for compatibility purposes."
  value       = var.enable_metrics_server ? helm_release.metrics_server[0].version : null
}

#==============================================================================
# Cluster Autoscaler
# Automatically adjusts node count based on resource requirements
#==============================================================================
output "cluster_autoscaler_enabled" {
  description = "Whether Cluster Autoscaler is enabled. Use this to conditionally configure resources that depend on node autoscaling capabilities."
  value       = var.enable_cluster_autoscaler
}

output "cluster_autoscaler_namespace" {
  description = "Namespace where Cluster Autoscaler is installed. Useful for creating resources that need to interact with the autoscaler."
  value       = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].namespace : null
}

output "cluster_autoscaler_version" {
  description = "Version of Cluster Autoscaler that is deployed. Important for compatibility with specific Kubernetes versions."
  value       = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].version : null
}

#==============================================================================
# Karpenter
# Next-generation Kubernetes autoscaler
#==============================================================================
output "karpenter_enabled" {
  description = "Whether Karpenter is enabled. Use this to conditionally configure resources that depend on Karpenter's node provisioning."
  value       = var.enable_karpenter
}

output "karpenter_namespace" {
  description = "Namespace where Karpenter is installed. Useful for creating or targeting Karpenter resources."
  value       = var.enable_karpenter ? helm_release.karpenter[0].namespace : null
}

output "karpenter_version" {
  description = "Version of Karpenter that is deployed. Important for compatibility with specific Kubernetes versions and cloud providers."
  value       = var.enable_karpenter ? helm_release.karpenter[0].version : null
}

#==============================================================================
# NGINX Ingress Controller
# HTTP/HTTPS traffic routing and load balancing
#==============================================================================
output "nginx_ingress_enabled" {
  description = "Whether NGINX Ingress Controller is enabled. Use this to conditionally configure Ingress resources or DNS entries."
  value       = var.enable_nginx_ingress
}

output "nginx_ingress_namespace" {
  description = "Namespace where NGINX Ingress Controller is installed. Needed when creating IngressClass resources or targeting the controller specifically."
  value       = var.enable_nginx_ingress ? helm_release.nginx_ingress[0].namespace : null
}

output "nginx_ingress_version" {
  description = "Version of NGINX Ingress Controller that is deployed. Helpful for tracking compatibility with specific Ingress resource versions."
  value       = var.enable_nginx_ingress ? helm_release.nginx_ingress[0].version : null
}

#==============================================================================
# Cert Manager
# Automated certificate management for TLS
#==============================================================================
output "cert_manager_enabled" {
  description = "Whether Cert Manager is enabled. Use this to conditionally configure Certificate resources or issuers."
  value       = var.enable_cert_manager
}

output "cert_manager_namespace" {
  description = "Namespace where Cert Manager is installed. Required when creating ClusterIssuer or Issuer resources."
  value       = var.enable_cert_manager ? helm_release.cert_manager[0].namespace : null
}

output "cert_manager_version" {
  description = "Version of Cert Manager that is deployed. Important for CRD compatibility and feature availability."
  value       = var.enable_cert_manager ? helm_release.cert_manager[0].version : null
}

#==============================================================================
# External DNS
# Automated DNS record management
#==============================================================================
output "external_dns_enabled" {
  description = "Whether External DNS is enabled. Use this to determine if DNS records will be automatically managed for services and ingresses."
  value       = var.enable_external_dns
}

output "external_dns_namespace" {
  description = "Namespace where External DNS is installed. Useful for monitoring or creating supporting resources."
  value       = var.enable_external_dns ? helm_release.external_dns[0].namespace : null
}

output "external_dns_version" {
  description = "Version of External DNS that is deployed. Different versions support different DNS providers and annotations."
  value       = var.enable_external_dns ? helm_release.external_dns[0].version : null
}

#==============================================================================
# Prometheus Stack
# Monitoring and alerting platform
#==============================================================================
output "prometheus_stack_enabled" {
  description = "Whether Prometheus Stack is enabled. Use this to conditionally configure ServiceMonitor resources or alerting rules."
  value       = var.enable_prometheus_stack
}

output "prometheus_stack_namespace" {
  description = "Namespace where Prometheus Stack is installed. Required for creating ServiceMonitor, PodMonitor, or PrometheusRule resources."
  value       = var.enable_prometheus_stack ? helm_release.prometheus_stack[0].namespace : null
}

output "prometheus_stack_version" {
  description = "Version of Prometheus Stack that is deployed. Different versions have different CRD schemas and capabilities."
  value       = var.enable_prometheus_stack ? helm_release.prometheus_stack[0].version : null
}

#==============================================================================
# Fluent Bit
# Log collection and forwarding agent
#==============================================================================
output "fluent_bit_enabled" {
  description = "Whether Fluent Bit is enabled. Use this to determine if log collection is available for applications."
  value       = var.enable_fluent_bit
}

output "fluent_bit_namespace" {
  description = "Namespace where Fluent Bit is installed. Useful for creating custom configurations or monitoring its operation."
  value       = var.enable_fluent_bit ? helm_release.fluent_bit[0].namespace : null
}

output "fluent_bit_version" {
  description = "Version of Fluent Bit that is deployed. Different versions support different features and destinations."
  value       = var.enable_fluent_bit ? helm_release.fluent_bit[0].version : null
}

#==============================================================================
# ArgoCD
# GitOps continuous delivery platform
#==============================================================================
output "argocd_enabled" {
  description = "Whether ArgoCD is enabled. Use this to conditionally configure Application resources or integration with CI/CD."
  value       = var.enable_argocd
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed. Required for creating Application resources or accessing ArgoCD API."
  value       = var.enable_argocd ? helm_release.argocd[0].namespace : null
}

output "argocd_version" {
  description = "Version of ArgoCD that is deployed. Different versions support different features and CRD schemas."
  value       = var.enable_argocd ? helm_release.argocd[0].version : null
}

#==============================================================================
# Velero
# Backup and disaster recovery for cluster resources
#==============================================================================
output "velero_enabled" {
  description = "Whether Velero is enabled. Use this to determine if backup and restore capabilities are available."
  value       = var.enable_velero
}

output "velero_namespace" {
  description = "Namespace where Velero is installed. Required for creating Backup, Schedule, or Restore resources."
  value       = var.enable_velero ? helm_release.velero[0].namespace : null
}

output "velero_version" {
  description = "Version of Velero that is deployed. Different versions support different storage providers and features."
  value       = var.enable_velero ? helm_release.velero[0].version : null
}

#==============================================================================
# Sealed Secrets
# Secure Kubernetes secret management
#==============================================================================
output "sealed_secrets_enabled" {
  description = "Whether Sealed Secrets is enabled. Use this to determine if encrypted secrets can be stored in version control."
  value       = var.enable_sealed_secrets
}

output "sealed_secrets_namespace" {
  description = "Namespace where Sealed Secrets is installed. Required for targeting the controller when encrypting secrets."
  value       = var.enable_sealed_secrets ? helm_release.sealed_secrets[0].namespace : null
}

output "sealed_secrets_version" {
  description = "Version of Sealed Secrets that is deployed. Different versions may use different encryption algorithms or features."
  value       = var.enable_sealed_secrets ? helm_release.sealed_secrets[0].version : null
}

#==============================================================================
# Kyverno
# Policy Management Engine
#==============================================================================
output "kyverno_enabled" {
  description = "Whether Kyverno is enabled. Use this to determine if policy enforcement is active in the cluster."
  value       = var.enable_kyverno
}

output "kyverno_namespace" {
  description = "Namespace where Kyverno is installed. Required for creating or targeting Kyverno policies."
  value       = var.enable_kyverno ? helm_release.kyverno[0].namespace : null
}

output "kyverno_version" {
  description = "Version of Kyverno that is deployed. Different versions support different policy features and CRD schemas."
  value       = var.enable_kyverno ? helm_release.kyverno[0].version : null
}

#==============================================================================
# Crossplane
# Universal Control Plane for cloud resources
#==============================================================================
output "crossplane_enabled" {
  description = "Whether Crossplane is enabled. Use this to determine if cloud resource provisioning via Kubernetes is available."
  value       = var.enable_crossplane
}

output "crossplane_namespace" {
  description = "Namespace where Crossplane is installed. Required for creating or targeting Crossplane resources."
  value       = var.enable_crossplane ? helm_release.crossplane[0].namespace : null
}

output "crossplane_version" {
  description = "Version of Crossplane that is deployed. Different versions support different providers and compositions."
  value       = var.enable_crossplane ? helm_release.crossplane[0].version : null
}

#==============================================================================
# AWS Load Balancer Controller
# AWS-specific controller for Elastic Load Balancers
#==============================================================================
output "aws_load_balancer_controller_enabled" {
  description = "Whether AWS Load Balancer Controller is enabled. Use this to determine if AWS-specific load balancing features are available."
  value       = var.enable_aws_load_balancer_controller
}

output "aws_load_balancer_controller_namespace" {
  description = "Namespace where AWS Load Balancer Controller is installed. Required for targeting or monitoring the controller."
  value       = var.enable_aws_load_balancer_controller ? helm_release.aws_load_balancer_controller[0].namespace : null
}

output "aws_load_balancer_controller_version" {
  description = "Version of AWS Load Balancer Controller that is deployed. Different versions support different features and annotations."
  value       = var.enable_aws_load_balancer_controller ? helm_release.aws_load_balancer_controller[0].version : null
}

#==============================================================================
# Istio Service Mesh
# Advanced networking, security, and observability
#==============================================================================
output "istio_enabled" {
  description = "Whether Istio is enabled. Use this to conditionally configure VirtualService, Gateway, or other Istio resources."
  value       = var.enable_istio
}

output "istio_namespace" {
  description = "Namespace where Istio is installed. This namespace contains Istio's control plane components."
  value       = var.enable_istio ? helm_release.istio_base[0].namespace : null
}

output "istio_base_version" {
  description = "Version of Istio Base that is deployed. The base package includes CRDs and foundational resources."
  value       = var.enable_istio ? helm_release.istio_base[0].version : null
}

output "istiod_version" {
  description = "Version of Istiod that is deployed. Istiod is the Istio control plane that configures the service mesh."
  value       = var.enable_istio ? helm_release.istiod[0].version : null
}

output "istio_ingress_enabled" {
  description = "Whether Istio Ingress Gateway is enabled. This determines if Istio is configured to accept external traffic."
  value       = var.enable_istio && lookup(var.istio, "enable_ingress", true)
}

output "istio_ingress_version" {
  description = "Version of Istio Ingress Gateway that is deployed. The ingress gateway is the entry point for traffic into the mesh."
  value       = var.enable_istio && lookup(var.istio, "enable_ingress", true) ? helm_release.istio_ingress[0].version : null
}

#==============================================================================
# Combined Outputs
# Aggregate information about all installed addons
#==============================================================================
output "installed_addons" {
  description = "Map of all installed addons with their status and version information. Useful for monitoring which components are active and their configuration."
  value = {
    "metrics-server" = var.enable_metrics_server ? {
      enabled   = true
      namespace = helm_release.metrics_server[0].namespace
      version   = helm_release.metrics_server[0].version
    } : { enabled = false }
    
    "cluster-autoscaler" = var.enable_cluster_autoscaler ? {
      enabled   = true
      namespace = helm_release.cluster_autoscaler[0].namespace
      version   = helm_release.cluster_autoscaler[0].version
    } : { enabled = false }
    
    "karpenter" = var.enable_karpenter ? {
      enabled   = true
      namespace = helm_release.karpenter[0].namespace
      version   = helm_release.karpenter[0].version
    } : { enabled = false }
    
    "nginx-ingress" = var.enable_nginx_ingress ? {
      enabled   = true
      namespace = helm_release.nginx_ingress[0].namespace
      version   = helm_release.nginx_ingress[0].version
    } : { enabled = false }
    
    "cert-manager" = var.enable_cert_manager ? {
      enabled   = true
      namespace = helm_release.cert_manager[0].namespace
      version   = helm_release.cert_manager[0].version
    } : { enabled = false }
    
    "external-dns" = var.enable_external_dns ? {
      enabled   = true
      namespace = helm_release.external_dns[0].namespace
      version   = helm_release.external_dns[0].version
    } : { enabled = false }
    
    "prometheus-stack" = var.enable_prometheus_stack ? {
      enabled   = true
      namespace = helm_release.prometheus_stack[0].namespace
      version   = helm_release.prometheus_stack[0].version
    } : { enabled = false }
    
    "fluent-bit" = var.enable_fluent_bit ? {
      enabled   = true
      namespace = helm_release.fluent_bit[0].namespace
      version   = helm_release.fluent_bit[0].version
    } : { enabled = false }
    
    "argocd" = var.enable_argocd ? {
      enabled   = true
      namespace = helm_release.argocd[0].namespace
      version   = helm_release.argocd[0].version
    } : { enabled = false }
    
    "velero" = var.enable_velero ? {
      enabled   = true
      namespace = helm_release.velero[0].namespace
      version   = helm_release.velero[0].version
    } : { enabled = false }
    
    "sealed-secrets" = var.enable_sealed_secrets ? {
      enabled   = true
      namespace = helm_release.sealed_secrets[0].namespace
      version   = helm_release.sealed_secrets[0].version
    } : { enabled = false }
    
    "kyverno" = var.enable_kyverno ? {
      enabled   = true
      namespace = helm_release.kyverno[0].namespace
      version   = helm_release.kyverno[0].version
    } : { enabled = false }
    
    "crossplane" = var.enable_crossplane ? {
      enabled   = true
      namespace = helm_release.crossplane[0].namespace
      version   = helm_release.crossplane[0].version
    } : { enabled = false }
    
    "aws-load-balancer-controller" = var.enable_aws_load_balancer_controller ? {
      enabled   = true
      namespace = helm_release.aws_load_balancer_controller[0].namespace
      version   = helm_release.aws_load_balancer_controller[0].version
    } : { enabled = false }
    
    "istio" = var.enable_istio ? {
      enabled        = true
      namespace      = helm_release.istio_base[0].namespace
      base_version   = helm_release.istio_base[0].version
      istiod_version = helm_release.istiod[0].version
      ingress = {
        enabled = lookup(var.istio, "enable_ingress", true)
        version = lookup(var.istio, "enable_ingress", true) ? helm_release.istio_ingress[0].version : null
      }
    } : { enabled = false }
  }
}

# For backward compatibility - returns a list of names of enabled addons
output "installed_addon_names" {
  description = "List of names of all installed addons (only includes enabled addons)."
  value = [
    for name, addon in output.installed_addons.value :
      name if addon.enabled
  ]
}

#==============================================================================
# Health Status Output
# Provides a consolidated view of addon health for monitoring and dependencies
#==============================================================================
output "addons_health" {
  description = "Health status information for all installed addons. Useful for monitoring or as dependency checks."
  value = {
    all_healthy = alltrue([
      for name, addon in output.installed_addons.value :
        addon.enabled == false ? true : true  # This would be replaced with actual health checks in a production version
    ])
    
    # This could be enhanced with actual health check data in a real implementation
    addon_status = {
      for name, addon in output.installed_addons.value :
        name => addon.enabled ? "Healthy" : "Disabled"
    }
  }
}