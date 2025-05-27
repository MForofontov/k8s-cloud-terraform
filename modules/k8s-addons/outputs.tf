# Kubernetes Addons Outputs

# ------------------------
# Metrics Server
# ------------------------
output "metrics_server_enabled" {
  description = "Whether Metrics Server is enabled"
  value       = var.enable_metrics_server
}

output "metrics_server_namespace" {
  description = "Namespace where Metrics Server is installed"
  value       = var.enable_metrics_server ? helm_release.metrics_server[0].namespace : null
}

output "metrics_server_version" {
  description = "Version of Metrics Server that is deployed"
  value       = var.enable_metrics_server ? helm_release.metrics_server[0].version : null
}

# ------------------------
# Cluster Autoscaler
# ------------------------
output "cluster_autoscaler_enabled" {
  description = "Whether Cluster Autoscaler is enabled"
  value       = var.enable_cluster_autoscaler
}

output "cluster_autoscaler_namespace" {
  description = "Namespace where Cluster Autoscaler is installed"
  value       = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].namespace : null
}

output "cluster_autoscaler_version" {
  description = "Version of Cluster Autoscaler that is deployed"
  value       = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].version : null
}

# ------------------------
# NGINX Ingress Controller
# ------------------------
output "nginx_ingress_enabled" {
  description = "Whether NGINX Ingress Controller is enabled"
  value       = var.enable_nginx_ingress
}

output "nginx_ingress_namespace" {
  description = "Namespace where NGINX Ingress Controller is installed"
  value       = var.enable_nginx_ingress ? helm_release.nginx_ingress[0].namespace : null
}

output "nginx_ingress_version" {
  description = "Version of NGINX Ingress Controller that is deployed"
  value       = var.enable_nginx_ingress ? helm_release.nginx_ingress[0].version : null
}

# ------------------------
# Cert Manager
# ------------------------
output "cert_manager_enabled" {
  description = "Whether Cert Manager is enabled"
  value       = var.enable_cert_manager
}

output "cert_manager_namespace" {
  description = "Namespace where Cert Manager is installed"
  value       = var.enable_cert_manager ? helm_release.cert_manager[0].namespace : null
}

output "cert_manager_version" {
  description = "Version of Cert Manager that is deployed"
  value       = var.enable_cert_manager ? helm_release.cert_manager[0].version : null
}

# ------------------------
# External DNS
# ------------------------
output "external_dns_enabled" {
  description = "Whether External DNS is enabled"
  value       = var.enable_external_dns
}

output "external_dns_namespace" {
  description = "Namespace where External DNS is installed"
  value       = var.enable_external_dns ? helm_release.external_dns[0].namespace : null
}

output "external_dns_version" {
  description = "Version of External DNS that is deployed"
  value       = var.enable_external_dns ? helm_release.external_dns[0].version : null
}

# ------------------------
# Prometheus Stack
# ------------------------
output "prometheus_stack_enabled" {
  description = "Whether Prometheus Stack is enabled"
  value       = var.enable_prometheus_stack
}

output "prometheus_stack_namespace" {
  description = "Namespace where Prometheus Stack is installed"
  value       = var.enable_prometheus_stack ? helm_release.prometheus_stack[0].namespace : null
}

output "prometheus_stack_version" {
  description = "Version of Prometheus Stack that is deployed"
  value       = var.enable_prometheus_stack ? helm_release.prometheus_stack[0].version : null
}

# ------------------------
# Fluent Bit
# ------------------------
output "fluent_bit_enabled" {
  description = "Whether Fluent Bit is enabled"
  value       = var.enable_fluent_bit
}

output "fluent_bit_namespace" {
  description = "Namespace where Fluent Bit is installed"
  value       = var.enable_fluent_bit ? helm_release.fluent_bit[0].namespace : null
}

output "fluent_bit_version" {
  description = "Version of Fluent Bit that is deployed"
  value       = var.enable_fluent_bit ? helm_release.fluent_bit[0].version : null
}

# ------------------------
# ArgoCD
# ------------------------
output "argocd_enabled" {
  description = "Whether ArgoCD is enabled"
  value       = var.enable_argocd
}

output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = var.enable_argocd ? helm_release.argocd[0].namespace : null
}

output "argocd_version" {
  description = "Version of ArgoCD that is deployed"
  value       = var.enable_argocd ? helm_release.argocd[0].version : null
}

# ------------------------
# Velero
# ------------------------
output "velero_enabled" {
  description = "Whether Velero is enabled"
  value       = var.enable_velero
}

output "velero_namespace" {
  description = "Namespace where Velero is installed"
  value       = var.enable_velero ? helm_release.velero[0].namespace : null
}

output "velero_version" {
  description = "Version of Velero that is deployed"
  value       = var.enable_velero ? helm_release.velero[0].version : null
}

# ------------------------
# Sealed Secrets
# ------------------------
output "sealed_secrets_enabled" {
  description = "Whether Sealed Secrets is enabled"
  value       = var.enable_sealed_secrets
}

output "sealed_secrets_namespace" {
  description = "Namespace where Sealed Secrets is installed"
  value       = var.enable_sealed_secrets ? helm_release.sealed_secrets[0].namespace : null
}

output "sealed_secrets_version" {
  description = "Version of Sealed Secrets that is deployed"
  value       = var.enable_sealed_secrets ? helm_release.sealed_secrets[0].version : null
}

# ------------------------
# Istio Service Mesh
# ------------------------
output "istio_enabled" {
  description = "Whether Istio is enabled"
  value       = var.enable_istio
}

output "istio_namespace" {
  description = "Namespace where Istio is installed"
  value       = var.enable_istio ? helm_release.istio_base[0].namespace : null
}

output "istio_base_version" {
  description = "Version of Istio Base that is deployed"
  value       = var.enable_istio ? helm_release.istio_base[0].version : null
}

output "istiod_version" {
  description = "Version of Istiod that is deployed"
  value       = var.enable_istio ? helm_release.istiod[0].version : null
}

output "istio_ingress_enabled" {
  description = "Whether Istio Ingress Gateway is enabled"
  value       = var.enable_istio && lookup(var.istio, "enable_ingress", true)
}

output "istio_ingress_version" {
  description = "Version of Istio Ingress Gateway that is deployed"
  value       = var.enable_istio && lookup(var.istio, "enable_ingress", true) ? helm_release.istio_ingress[0].version : null
}

# ------------------------
# Combined Outputs
# ------------------------
output "installed_addons" {
  description = "List of all installed addons"
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