resource "kubectl_manifest" "fluentbit_input_youtoo" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterInput"
    metadata = {
      name      = "tail-youtoo-ingestion"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      tail = {
        tag                    = "kube.*"
        path                   = "/var/log/containers/youtoo-ingestion-*_${kubernetes_namespace.application_namespace.metadata[0].name}_youtoo-ingestion-*.log"
        readFromHead           = true
        parser                 = var.log_parser
        refreshIntervalSeconds = 10
        memBufLimit            = "64MB"
        skipLongLines          = true
        db                     = "/fluent-bit/tail/pos-youtoo-ingestion.db"
        dbSync                 = "Normal"
      }
    }
  })
}

resource "kubectl_manifest" "cluster_output_youtoo_seq" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterOutput"
    metadata = {
      name      = "output-ingestion-seq"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      match = "kube.*"

      # stdout = {
      #   format = "json_lines"
      # }

      gelf = {
        host            = "${helm_release.seq.name}.${kubernetes_namespace.telemetry.metadata[0].name}.svc.cluster.local"
        port            = 12201
        shortMessageKey = "message"
        fullMessageKey  = "message"
        timestampKey    = "date"
        mode            = "tcp"
        networking = {
          DNSMode        = "TCP"
          connectTimeout = 90
          DNSResolver    = "LEGACY"

        }

      }

    }

  })

}

resource "kubectl_manifest" "cluster_output_youtoo_opensearch" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterOutput"
    metadata = {
      name      = "output-ingestion-opensearch"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      match = "kube.*"

      # stdout = {
      #   format = "json_lines"
      # }

      opensearch = {
        host            = var.opensearch_host
        port            = 9200
        index           = "logs"
        logstashFormat = true
        logstashPrefix = "youtoo-logs"
        suppressTypeName = true
        replaceDots = true
        timeKey = "time"

        includeTagKey = true

        httpPassword = {
          valueFrom = {
            secretKeyRef = {
              key = "OPENSEARCH_AUTH_PASSWORD"
              name = "youtoo-application-secrets"
            }

          }

        }

        httpUser = {
          valueFrom = {
            secretKeyRef = {
              key = "OPENSEARCH_AUTH_USERNAME"
              name = "youtoo-application-secrets"
            }

          }

        }

        networking = {
          DNSMode        = "TCP"
          connectTimeout = 90
          DNSResolver    = "LEGACY"

        }

        tls = {
          verify = false
        }

      }

    }

  })

}

