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

The project includes a comprehensive Makefile for all Terraform operations. Use these commands for development:

```bash
# Full validation workflow (recommended for all changes)
make check

# Individual operations
make init           # Initialize Terraform
make validate       # Validate configuration
make format         # Format Terraform files
make security       # Run security scan
make plan           # Create execution plan
make apply          # Apply changes
make destroy        # Destroy resources

# Environment-specific workflows
make dev            # Development workflow
make staging        # Staging workflow
make prod           # Production workflow (with extra safety)

# Utility commands
make status         # Show current status
make clean          # Clean temporary files
make backup         # Backup state files
make help           # Show all available targets
```

**IMPORTANT: Always run `make check` before committing changes to ensure code quality and security.**

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

## Development Workflow for Claude Code

When making ANY changes to Terraform files, ALWAYS run validation checks using the Makefile:

1. **After editing any .tf file**: `make check`
2. **Before committing changes**: `make check`
3. **Quick validation during development**: `make validate format`
4. **Security check**: `make security`

The `make check` command runs the complete workflow: init → validate → format → security → plan

This ensures code quality, security compliance, and prevents deployment issues.