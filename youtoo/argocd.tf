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

resource "helm_release" "argocd_apps" {
  depends_on = [
    helm_release.argocd,
  ]

  name       = "argocd-apps"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.2"

  values = [
    yamlencode({
      applications = {
        youtoo = {
          name                  = "youtoo"
          namespace             = "argocd"
          additionalLabels      = {}
          additionalAnnotations = {}
          finalizers = [
            "resources-finalizer.argocd.argoproj.io"

          ]

          project = "default"

          source = {
            repoURL        = "https://gitlab.com/therealcisse/youtoo-manifests.git"
            targetRevision = "main"
            path           = "overlays/local"
            kustomize      = {}
          }

          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "youtoo"
          }

          syncPolicy = {
            automated = {
              prune     = true
              self_heal = true
            }
          }

        }

      }

    })

  ]
}
