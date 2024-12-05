provider "kubernetes" {
  config_path = "~/.kube/config"
}

data "hcp_vault_secrets_app" "youtoo" {
  app_name = "youtoo"
}
