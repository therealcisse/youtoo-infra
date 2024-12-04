resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace = kubernetes_namespace.external_secrets.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.11.0"

  create_namespace = false

  values = [
  ]

}

resource "kubernetes_secret" "doppler-token-auth-api" {
  metadata {
    name      = "doppler-token-auth-api"
    namespace = kubernetes_namespace.application_namespace.metadata[0].name
  }

  data = {
    "dopplerToken" = var.doppler_auth_token
  }
}

resource "kubectl_manifest" "doppler-secret-store" {

  depends_on = [
    helm_release.external_secrets
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "SecretStore"
    "metadata"   = {
      "name"      = "doppler-secret-store"
      "namespace" = kubernetes_namespace.application_namespace.metadata[0].name
    }
    "spec" = {
      "provider" = {
        "doppler" = {
          "auth" = {
            "secretRef" = {
              "dopplerToken" = {
                "name" = "doppler-token-auth-api"
                "key" = "dopplerToken"
              }
            }
          }
        }
      }
    }
  })
}

resource "kubectl_manifest" "app-secrets" {

  depends_on = [
    helm_release.external_secrets
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    "apiVersion" = "external-secrets.io/v1beta1"
    "kind"       = "ExternalSecret"
    "metadata"   = {
      "name"      = "app-secrets"
      "namespace" = kubernetes_namespace.application_namespace.metadata[0].name
    }
    "spec" = {
      "refreshInterval" = "1h"
      "secretStoreRef"  = {
        "name" = "doppler-secret-store"
        "kind" = "SecretStore"
      }
      "target" = {
        "name"           = "app-secrets"
        "creationPolicy" = "Owner"
      }
      "data" = [
        {
          "secretKey" = "DATABASE_USERNAME"
          "remoteRef" = {
            "key" = "DATABASE_USERNAME"
          }
        },
        {
          "secretKey" = "DATABASE_PASSWORD"
          "remoteRef" = {
            "key" = "DATABASE_PASSWORD"
          }
        }
      ]
    }
  })
}

