resource "kubectl_manifest" "cluster_parser_log_parser_json" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  server_side_apply = true


  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterParser"
    metadata = {
      name      = "youtoo-log-json"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      decoders = [
        {
          decodeFieldAs = "json log remove_key=true"
        }
      ]
      json = {
        timeKey    = "time"
        timeFormat = "%Y-%m-%dT%H:%M:%S %z"
      }
    }
  })
}

resource "kubectl_manifest" "cluster_parser_log_parser_docker" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  server_side_apply = true


  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterParser"
    metadata = {
      name      = "youtoo-log-docker"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      decoders = [
        {
          decodeFieldAs = "json log remove_key=true"
        }
      ]
      regex = {
        timeKey    = "timestamp"
        timeFormat = "%Y-%m-%dT%H:%M:%S.%L%z"
        regex      = "/^(?<timestamp>.+) (?<stream>stdout|stderr) (?<logtag>[FP]) (?<log>.*)$/"
        timeKeep   = false
      }
    }
  })
}


