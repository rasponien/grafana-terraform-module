data "azuread_client_config" "current" {}

resource "azuread_application" "grafana" {
  display_name = "${var.grafana_name}-oidc"
  owners       = [data.azuread_client_config.current.object_id]

  web {
    redirect_uris = [
      "https://${var.grafana_domain}/login/azuread"
    ]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # openid
      type = "Scope"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }
  }

  tags = values(var.tags)
}

resource "azuread_service_principal" "grafana" {
  client_id                    = azuread_application.grafana.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]

  tags = values(var.tags)
}

resource "azuread_application_password" "grafana" {
  application_object_id = azuread_application.grafana.object_id
  display_name          = "${var.grafana_name}-secret"
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

resource "kubernetes_secret" "grafana_azure_secret" {
  metadata {
    name      = "${var.grafana_name}-azure-secret"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }

  data = {
    client_id     = azuread_application.grafana.client_id
    client_secret = azuread_application_password.grafana.value
  }
}

locals {
  grafana_values = {
    "adminUser"     = "admin"
    "adminPassword" = "changeme"

    "persistence" = {
      "enabled"          = var.enable_persistence
      "size"             = var.storage_size
      "storageClassName" = "default"
    }

    "ingress" = {
      "enabled"          = true
      "ingressClassName" = var.ingress_class
      "hosts"            = [var.grafana_domain]
      "tls" = [{
        "secretName" = "${var.grafana_name}-tls"
        "hosts"      = [var.grafana_domain]
      }]
    }

    "grafana.ini" = {
      "server" = {
        "root_url" = "https://${var.grafana_domain}"
      }
      "auth.azuread" = {
        "enabled"                    = true
        "name"                       = "Azure AD"
        "allow_sign_up"              = true
        "client_id"                  = "$__env{GF_AUTH_AZUREAD_CLIENT_ID}"
        "client_secret"              = "$__env{GF_AUTH_AZUREAD_CLIENT_SECRET}"
        "scopes"                     = "openid email profile"
        "auth_url"                   = "https://login.microsoftonline.com/${var.azure_tenant_id}/oauth2/v2.0/authorize"
        "token_url"                  = "https://login.microsoftonline.com/${var.azure_tenant_id}/oauth2/v2.0/token"
        "api_url"                    = "https://graph.microsoft.com/oidc/userinfo"
        "allowed_domains"            = ""
        "team_ids"                   = ""
        "allowed_organizations"      = ""
        "role_attribute_path"        = ""
        "role_attribute_strict"      = false
        "allow_assign_grafana_admin" = false
        "skip_org_role_sync"         = false
      }
    }

    "extraSecretMounts" = [{
      "name"        = "azure-secret-mount"
      "secretName"  = kubernetes_secret.grafana_azure_secret.metadata[0].name
      "defaultMode" = 0440
      "mountPath"   = "/etc/secrets/azure"
      "readOnly"    = true
    }]

    "env" = {
      "GF_AUTH_AZUREAD_CLIENT_ID" = {
        "valueFrom" = {
          "secretKeyRef" = {
            "name" = kubernetes_secret.grafana_azure_secret.metadata[0].name
            "key"  = "client_id"
          }
        }
      }
      "GF_AUTH_AZUREAD_CLIENT_SECRET" = {
        "valueFrom" = {
          "secretKeyRef" = {
            "name" = kubernetes_secret.grafana_azure_secret.metadata[0].name
            "key"  = "client_secret"
          }
        }
      }
    }
  }
}

resource "helm_release" "grafana" {
  name       = var.grafana_name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.chart_version
  namespace  = kubernetes_namespace.grafana.metadata[0].name

  values = [
    yamlencode(local.grafana_values)
  ]

  depends_on = [
    kubernetes_secret.grafana_azure_secret
  ]
}