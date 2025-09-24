variable "grafana_name" {
  description = "Name for the Grafana deployment"
  type        = string
  default     = "grafana"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy Grafana"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Version of the Grafana Helm chart"
  type        = string
  default     = "7.0.19"
}

variable "azure_tenant_id" {
  description = "Azure tenant ID for OIDC authentication"
  type        = string
}

variable "grafana_domain" {
  description = "Domain where Grafana will be accessible"
  type        = string
}

variable "admin_email" {
  description = "Email address for the Grafana admin user"
  type        = string
}

variable "storage_size" {
  description = "Size of persistent storage for Grafana"
  type        = string
  default     = "10Gi"
}

variable "ingress_class" {
  description = "Ingress class to use for Grafana"
  type        = string
  default     = "nginx"
}

variable "enable_persistence" {
  description = "Enable persistent storage for Grafana"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to Azure resources"
  type        = map(string)
  default     = {}
}