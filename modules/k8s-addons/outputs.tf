#==============================================================================
# Kubernetes Addons Module Outputs
#
# This file defines the output values provided by the Kubernetes Addons module.
# Each addon has a set of outputs that include:
#   - Whether the addon is enabled
#   - The namespace where the addon is installed
#   - The version of the addon that is deployed
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
  description = "List of all installed addons. Useful for monitoring which components are active in the cluster or for conditional logic in dependent modules."
  value = [
    var.enable_metrics_server ? "metrics-server" : "",
    var.enable_cluster_autoscaler ? "cluster-autoscaler" : "",
    var.enable_nginx_ingress ? "nginx-ingress" : "",
    var.enable_cert_manager ? "cert-manager" : "",
    var.enable_external_dns ? "external-dns" : "",
    var.enable_prometheus_stack ? "prometheus-stack" : "",
    var.enable_fluent_bit ? "fluent-bit" : "",
    var.enable_argocd ? "argocd" : "",
    var.enable_velero ? "velero" : "",
    var.enable_sealed_secrets ? "sealed-secrets" : "",
    var.enable_istio ? "istio" : ""
  ]
}