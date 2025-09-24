# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform module for deploying self-hosted Grafana on Azure Kubernetes Service (AKS) with Azure AD OIDC authentication integration. The module uses Helm charts to deploy Grafana and automatically configures Azure AD application registration for seamless authentication.

## Architecture

The module creates a complete deployment stack:

- **Azure AD Integration** (`main.tf:3-51`): Creates Azure AD application, service principal, and application password for OIDC authentication
- **Kubernetes Resources** (`main.tf:53-72`): Manages namespace and secrets for storing Azure AD credentials
- **Helm Deployment** (`main.tf:148-162`): Deploys Grafana using official Helm chart with custom values for OIDC configuration
- **Configuration Management** (`main.tf:74-146`): Uses locals block to generate complex Grafana configuration including OIDC settings, ingress, and persistence

The key integration point is the `grafana_values` local that translates module variables into Helm chart values, specifically configuring Azure AD OIDC authentication through environment variables sourced from Kubernetes secrets.

## Common Commands

```bash
# Initialize and validate the module
terraform init
terraform validate
terraform fmt

# Plan and apply (from examples/ directory)
cd examples/
terraform plan
terraform apply

# Test the module locally
terraform plan -var="azure_tenant_id=your-tenant-id" -var="grafana_domain=grafana.local" -var="admin_email=admin@local"

# Destroy resources
terraform destroy
```

## Key Configuration Points

- **Azure AD App Registration**: Automatically creates with proper redirect URI format: `https://${var.grafana_domain}/login/azuread`
- **OIDC Configuration**: Located in `main.tf:99-116`, uses Azure AD v2.0 endpoints
- **Secret Management**: Azure credentials are stored in `kubernetes_secret.grafana_azure_secret` and mounted as environment variables
- **Helm Values**: The `local.grafana_values` block contains the complete Grafana configuration including OIDC auth settings

## Prerequisites for Usage

- Existing AKS cluster with kubectl access configured
- Domain name for Grafana access
- Ingress controller (nginx) installed in the cluster
- Azure subscription with appropriate permissions for creating AD applications

The module expects to be consumed as a child module, not executed directly. See `examples/main.tf` for proper usage patterns.