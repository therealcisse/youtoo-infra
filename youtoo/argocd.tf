resource "helm_release" "argocd" {
  depends_on = []

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.7.7"

  namespace = "argocd"

  create_namespace = true

  # set {
  #   name  = "server.service.type"
  #   value = "LoadBalancer"
  # }

  # set {
  #   name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
  #   value = "nlb"
  # }

  values = [
    file("${path.module}/argocd/values.yml")
  ]
}

resource "argocd_application" "youtoo" {
  depends_on = [
    helm_release.argocd,
  ]

  metadata {
    name      = "youtoo"
    namespace = "argocd"
  }

  spec {
    project = "default"
    source {
      repo_url        = "https://gitlab.com/therealcisse/youtoo-manifests.git"
      target_revision = "main"
      path            = "overlays/app"
    }
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "youtoo"
    }
    sync_policy {
      automated {
        prune     = false
        self_heal = false
      }
    }
  }
}
