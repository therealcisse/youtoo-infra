resource "helm_release" "fluent_operator" {
  depends_on = [
    helm_release.cert_manager,
    helm_release.prometheus_operator,
  ]

  name       = "fluent-operator"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-operator"
  version    = "3.2.0"
  namespace  = kubernetes_namespace.telemetry.metadata[0].name

  create_namespace = false

  timeout = 3600

  values = [
    yamlencode({
      operator = {
        disableComponentControllers = "fluentd"

      }

      fluentBitMetrics = {
        scrapeInterval = "2"
        scrapeOnStart  = true
        tag            = "fb.metrics"
      }

      fluentd = {
        crdsEnable = false
        enable     = false
      }

      fluentbit = {
        image = {
          repository = "cr.fluentbit.io/fluent/fluent-bit"
          tag        = "3.2.1"

        }

        crdsEnable = true
        enable     = true

        input = {
          tail = {
            enable = false
          }
        }

        output = {

          stdout = {
            enable = false
          }
        }

        serviceMonitor = {
          enable            = true
          interval          = "30s"
          path              = "/api/v2/metrics/prometheus"
          scrapeTimeout     = "30s"
          secure            = false
          tlsConfig         = {}
          relabelings       = []
          metricRelabelings = []
        }

      }

    })
  ]

  wait = true
}

resource "time_sleep" "wait_for_fluentbit_operator" {

  depends_on = [
    helm_release.fluent_operator
  ]

  create_duration = "30s"
}

resource "kubectl_manifest" "fluentbit_k8s_filter" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  # server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterFilter"
    metadata = {
      name      = "kubernetes"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      match = "kube.*"
      filters = [
        {
          kubernetes = {
            kubeURL       = "https://kubernetes.default.svc:443"
            kubeCAFile    = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
            kubeTokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token"
            labels        = false
            annotations   = false
          }
        },
        {
          nest = {
            operation   = "lift"
            nestedUnder = "kubernetes"
            addPrefix   = "k8s_"
          }
        },
        {
          modify = {
            rules = [
              { remove = "stream" },
              { remove = "k8s_pod_id" },
              { remove = "k8s_host" },
              { remove = "k8s_container_hash" },
              { remove = "logtag" },
            ]
          }
        },
        {
          nest = {
            operation    = "nest"
            wildcard     = ["k8s_*"]
            nestUnder    = "k8s"
            removePrefix = "k8s_"
          }
        }
      ]
    }
  })
}

resource "kubectl_manifest" "fluentbit_filter" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  # server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterFilter"
    metadata = {
      name      = "youtoo-log-filter"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      match = "kube.*"
      filters = [
        {
          nest = {
            operation   = "lift"
            nestedUnder = "log"
          }
        }
      ]
    }
  })
}

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

resource "kubectl_manifest" "fluentbit-input-metrics" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterInput"
    metadata = {
      name      = "fluentbit-metrics"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      fluentBitMetrics = {
        tag            = "internal_metrics"
        scrapeInterval = "15s"

      }
    }
  })
}

# resource "kubectl_manifest" "fluentbit_input_kube" {
#   depends_on = [
#     time_sleep.wait_for_fluentbit_operator,
#   ]
#
#   # server_side_apply = true
#
#   yaml_body = yamlencode({
#     apiVersion = "fluentbit.fluent.io/v1alpha2"
#     kind       = "ClusterInput"
#     metadata = {
#       name = "tail-kube"
#       namespace = kubernetes_namespace.telemetry.metadata[0].name
#       labels = {
#         "fluentbit.fluent.io/enabled"   = "true"
#         "fluentbit.fluent.io/mode"      = "k8s"
#         "fluentbit.fluent.io/component" = "system"
#       }
#     }
#     spec = {
#       tail = {
#         tag                    = "kube.*"
#         path                   = "/var/log/containers/*.log"
#         excludePath            = "/var/log/containers/youtoo-ingestion-*_${kubernetes_namespace.application_namespace.metadata[0].name}_youtoo-ingestion-*.log,/var/log/containers/*_kube*-system_*.log"
#         parser                 = "docker"
#         refreshIntervalSeconds = 30
#         memBufLimit            = "64MB"
#         skipLongLines          = true
#         db                     = "/fluent-bit/tail/pos-kube.db"
#         dbSync                 = "Normal"
#       }
#     }
#
#   })
# }


resource "kubectl_manifest" "fluentbit_clusterconfig" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  # server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterFluentBitConfig"
    metadata = {
      name      = "fluent-bit-config"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = "fluent-bit"
      }
    }
    spec = {
      service = {
        daemon      = false
        httpServer  = true
        parsersFile = "custom-parsers.conf"
        logLevel    = "info"
      }
      inputSelector = {
        matchLabels = {
          "fluentbit.fluent.io/enabled" = "true"
          "fluentbit.fluent.io/mode"    = "k8s"
        }
      }
      filterSelector = {
        matchLabels = {
          "fluentbit.fluent.io/enabled" = "true"
          "fluentbit.fluent.io/mode"    = "k8s"
        }
      }
      outputSelector = {
        matchLabels = {
          "fluentbit.fluent.io/enabled" = "true"
          "fluentbit.fluent.io/mode"    = "k8s"
        }
      }
    }
  })
}

resource "kubectl_manifest" "fluentbit" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  # server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "FluentBit"
    metadata = {
      name      = "fluent-bit"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = "fluent-bit"
      }
    }
    spec = {
      image = "kubesphere/fluent-bit:v3.1.8"
      positionDB = {
        hostPath = {
          path = "/var/lib/fluent-bit/"
        }
      }
      resources = {
        requests = {
          cpu    = "10m"
          memory = "25Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "200Mi"
        }
      }
      fluentBitConfigName = "fluent-bit-config"
      tolerations = [
        {
          operator = "Exists"
        }
      ]
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key      = "node-role.kubernetes.io/edge"
                    operator = "DoesNotExist"
                  }
                ]
              }
            ]
          }
        }
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

resource "kubectl_manifest" "fluentbit-internal-metrics" {
  depends_on = [
    time_sleep.wait_for_fluentbit_operator,
  ]

  server_side_apply = true

  yaml_body = yamlencode({
    apiVersion = "fluentbit.fluent.io/v1alpha2"
    kind       = "ClusterOutput"
    metadata = {
      name      = "fluentbit-internal-metrics"
      namespace = kubernetes_namespace.telemetry.metadata[0].name
      labels = {
        "fluentbit.fluent.io/enabled" = "true"
        "fluentbit.fluent.io/mode"    = "k8s"
      }
    }
    spec = {
      match = "internal_metrics"

      # stdout = {
      #   format = "json_lines"
      # }

      prometheusExporter = {
        host = "0.0.0.0"
        port = 2021
      }

    }

  })

}

# resource "kubectl_manifest" "cluster_output_youtoo_opensearch" {
#   depends_on = [
#     time_sleep.wait_for_fluentbit_operator,
#   ]
#
#   server_side_apply = true
#
#   yaml_body = yamlencode({
#     apiVersion = "fluentbit.fluent.io/v1alpha2"
#     kind       = "ClusterOutput"
#     metadata = {
#       name      = "output-ingestion-opensearch"
#       namespace = kubernetes_namespace.telemetry.metadata[0].name
#       labels = {
#         "fluentbit.fluent.io/enabled" = "true"
#         "fluentbit.fluent.io/mode"    = "k8s"
#       }
#     }
#     spec = {
#       match = "kube.*"
#
#       # stdout = {
#       #   format = "json_lines"
#       # }
#
#       opensearch = {
#         host            = var.opensearch_host
#         port            = 9200
#         index           = "logs"
#         type            = "_doc"
#         networking = {
#           DNSMode        = "TCP"
#           connectTimeout = 90
#           DNSResolver    = "LEGACY"
#
#         }
#
#       }
#
#     }
#
#   })
#
# }

# resource "kubectl_manifest" "cluster_output_kube_seq" {
#   depends_on = [
#     time_sleep.wait_for_fluentbit_operator,
#   ]
#
#   # server_side_apply = true
#
#   yaml_body = yamlencode({
#     apiVersion = "fluentbit.fluent.io/v1alpha2"
#     kind       = "ClusterOutput"
#     metadata = {
#       name = "output-kube-seq"
#       namespace = kubernetes_namespace.telemetry.metadata[0].name
#       labels = {
#         "fluentbit.fluent.io/enabled"   = "true"
#         "fluentbit.fluent.io/mode"      = "k8s"
#         "fluentbit.fluent.io/component" = "system"
#       }
#     }
#     spec = {
#       match = "kube.*"
#       gelf = {
#         host            = "${helm_release.seq.name}.${kubernetes_namespace.telemetry.metadata[0].name}.svc.cluster.local"
#         port            = 12201
#         shortMessageKey = "message"
#         mode            = "tcp"
#
#       }
#
#     }
#
#   })
#
# }

