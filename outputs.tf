output "azure_ad_application_id" {
  description = "Application ID of the Azure AD app registration"
  value       = azuread_application.grafana.client_id
}

output "azure_ad_client_secret" {
  description = "Client secret for the Azure AD application"
  value       = azuread_application_password.grafana.value
  sensitive   = true
}

output "grafana_url" {
  description = "URL where Grafana is accessible"
  value       = "https://${var.grafana_domain}"
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.grafana.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.grafana.namespace
}