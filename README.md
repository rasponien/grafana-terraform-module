# Grafana Terraform Module

A Terraform module for deploying self-hosted Grafana on Azure Kubernetes Service (AKS) with Azure AD OIDC authentication using Helm charts.

## Features

- ✅ Grafana deployment via Helm chart
- ✅ Azure AD OIDC authentication integration
- ✅ Automatic Azure AD application registration
- ✅ Kubernetes secret management
- ✅ Persistent storage support
- ✅ Ingress configuration with TLS

## Prerequisites

- Azure subscription with AKS cluster
- Terraform >= 1.0
- kubectl configured to access your AKS cluster
- Domain name for Grafana access
- Ingress controller (e.g., nginx-ingress) installed in the cluster

## Usage

```hcl
module "grafana" {
  source = "path/to/grafana-terraform-module"

  grafana_name      = "my-grafana"
  namespace         = "monitoring"
  azure_tenant_id   = "your-tenant-id"
  grafana_domain    = "grafana.yourdomain.com"
  admin_email       = "admin@yourdomain.com"
  storage_size      = "20Gi"
  ingress_class     = "nginx"
  enable_persistence = true

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| grafana_name | Name for the Grafana deployment | `string` | `"grafana"` | no |
| namespace | Kubernetes namespace to deploy Grafana | `string` | `"monitoring"` | no |
| chart_version | Version of the Grafana Helm chart | `string` | `"7.0.19"` | no |
| azure_tenant_id | Azure tenant ID for OIDC authentication | `string` | n/a | yes |
| grafana_domain | Domain where Grafana will be accessible | `string` | n/a | yes |
| admin_email | Email address for the Grafana admin user | `string` | n/a | yes |
| storage_size | Size of persistent storage for Grafana | `string` | `"10Gi"` | no |
| ingress_class | Ingress class to use for Grafana | `string` | `"nginx"` | no |
| enable_persistence | Enable persistent storage for Grafana | `bool` | `true` | no |
| tags | Tags to apply to Azure resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| azure_ad_application_id | Application ID of the Azure AD app registration |
| azure_ad_client_secret | Client secret for the Azure AD application (sensitive) |
| grafana_url | URL where Grafana is accessible |
| helm_release_name | Name of the Helm release |
| helm_release_namespace | Namespace of the Helm release |

## Post-Deployment Steps

1. **Configure DNS**: Point your domain to the ingress controller's external IP
2. **Set up TLS certificate**: Configure cert-manager or manually create TLS certificates
3. **Configure Azure AD permissions**: Grant necessary permissions to the created Azure AD application
4. **Access Grafana**: Navigate to `https://your-grafana-domain.com` and sign in with Azure AD

## Security Considerations

- The module creates Azure AD application credentials automatically
- Client secrets are stored securely in Kubernetes secrets
- Default admin credentials should be changed after initial deployment
- Consider implementing network policies for additional security

## Examples

See the [examples](./examples/) directory for complete usage examples.

## License

MIT