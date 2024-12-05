resource "kubernetes_namespace" "vault_secrets_operator" {
  metadata {
    name = "vault-secrets-operator-system"
  }
}

resource "helm_release" "vault_secrets_operator" {
  name       = "vault-secrets-operator"
  namespace  = kubernetes_namespace.vault_secrets_operator.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"
  version    = "0.9.0"

  create_namespace = false

}

resource "kubernetes_secret" "vso-youtoo-sp" {
  metadata {
    name      = "hcp-vault-secrets-youtoo"
    namespace = kubernetes_namespace.application_namespace.metadata[0].name
  }

  data = {
    clientID     = var.HCP_CLIENT_ID
    clientSecret = var.HCP_CLIENT_SECRET
  }
}

resource "kubectl_manifest" "hcp_auth" {
  depends_on = [
    helm_release.vault_secrets_operator,
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "HCPAuth"
    metadata = {
      name      = "default"
      namespace = kubernetes_namespace.vault_secrets_operator.metadata[0].name
    }
    spec = {
      organizationID = var.HCP_ORG_ID
      projectID      = var.HCP_PROJECT_ID
      servicePrincipal = {
        secretRef = kubernetes_secret.vso-youtoo-sp.metadata[0].name
      }
    }
  })
}

resource "kubectl_manifest" "hcp_vault_secrets_app" {
  depends_on = [
    helm_release.vault_secrets_operator,
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "HCPVaultSecretsApp"
    metadata = {
      name      = "youtoo"
      namespace = kubernetes_namespace.application_namespace.metadata[0].name
    }
    spec = {
      appName      = var.APP_NAME
      refreshAfter = "30s"
      destination = {
        create = true
        labels = {
          hvs      = "true"
          rotating = "false"
        }
        name = "youtoo-application-secrets"
      }
    }
  })
}

