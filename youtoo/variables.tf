variable "jaeger_operator_chart_version" {
  type        = string
  description = "Version of the jaeger-operator chart"
  default     = "2.57.0"
}

variable "cert_manager_release" {
  type    = string
  default = "1.16.2"
}

variable "log_parser" {
  type = string

}

variable "HCP_CLIENT_ID" {
  type = string

}

variable "HCP_CLIENT_SECRET" {
  type = string

}


variable "HCP_ORG_ID" {
  type = string

}

variable "HCP_PROJECT_ID" {
  type = string

}

variable "APP_NAME" {
  type = string

}

variable "argocd_target_revision" {
  type    = string
  default = "main"

}

variable "opensearch_host" {
  type = string
}
