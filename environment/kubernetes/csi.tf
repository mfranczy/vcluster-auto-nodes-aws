############################
# ServiceAccounts
############################

resource "kubernetes_service_account_v1" "ebs_csi_controller_sa" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_service_account_v1" "ebs_csi_node_sa" {
  metadata {
    name      = "ebs-csi-node-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  automount_service_account_token = true
}

############################
# RBAC: Role / ClusterRoles
############################

resource "kubernetes_role_v1" "ebs_csi_leases_role" {
  metadata {
    name      = "ebs-csi-leases-role"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get","watch","list","delete","update","create"]
  }
}

resource "kubernetes_cluster_role_v1" "ebs_csi_node_role" {
  metadata {
    name = "ebs-csi-node-role"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get","patch","list","watch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments"]
    verbs      = ["get","list","watch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csinodes"]
    verbs      = ["get"]
  }
}

resource "kubernetes_cluster_role_v1" "ebs_external_attacher_role" {
  metadata {
    name = "ebs-external-attacher-role"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get","list","watch","patch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csinodes"]
    verbs      = ["get","list","watch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments"]
    verbs      = ["get","list","watch","patch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments/status"]
    verbs      = ["patch"]
  }
}

resource "kubernetes_cluster_role_v1" "ebs_external_provisioner_role" {
  metadata {
    name = "ebs-external-provisioner-role"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get","list","watch","create","patch","delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get","list","watch","update"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get","list","watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list","watch","create","update","patch"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshots","volumesnapshotcontents"]
    verbs      = ["get","list"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csinodes","volumeattachments","volumeattributesclasses"]
    verbs      = ["get","list","watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get","list","watch"]
  }
}

resource "kubernetes_cluster_role_v1" "ebs_external_resizer_role" {
  metadata {
    name = "ebs-external-resizer-role"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get","list","watch","patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims","pods"]
    verbs      = ["get","list","watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims/status"]
    verbs      = ["patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list","watch","create","update","patch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattributesclasses"]
    verbs      = ["get","list","watch"]
  }
}

resource "kubernetes_cluster_role_v1" "ebs_external_snapshotter_role" {
  metadata {
    name = "ebs-external-snapshotter-role"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list","watch","create","update","patch"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotclasses"]
    verbs      = ["get","list","watch"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents"]
    verbs      = ["get","list","watch","update","patch"]
  }
  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents/status"]
    verbs      = ["update","patch"]
  }
  rule {
    api_groups = ["groupsnapshot.storage.k8s.io"]
    resources  = ["volumegroupsnapshotclasses"]
    verbs      = ["get","list","watch"]
  }
  rule {
    api_groups = ["groupsnapshot.storage.k8s.io"]
    resources  = ["volumegroupsnapshotcontents"]
    verbs      = ["get","list","watch","update","patch"]
  }
  rule {
    api_groups = ["groupsnapshot.storage.k8s.io"]
    resources  = ["volumegroupsnapshotcontents/status"]
    verbs      = ["update","patch"]
  }
}

############################
# RBAC Bindings
############################

resource "kubernetes_role_binding_v1" "ebs_csi_leases_rolebinding" {
  metadata {
    name      = "ebs-csi-leases-rolebinding"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.ebs_csi_leases_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ebs_csi_controller_sa.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "ebs_csi_attacher_binding" {
  metadata {
    name = "ebs-csi-attacher-binding"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.ebs_external_attacher_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ebs_csi_controller_sa.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "ebs_csi_node_getter_binding" {
  metadata {
    name = "ebs-csi-node-getter-binding"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.ebs_csi_node_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ebs_csi_node_sa.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "ebs_csi_provisioner_binding" {
  metadata {
    name = "ebs-csi-provisioner-binding"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.ebs_external_provisioner_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ebs_csi_controller_sa.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "ebs_csi_resizer_binding" {
  metadata {
    name = "ebs-csi-resizer-binding"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.ebs_external_resizer_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ebs_csi_controller_sa.metadata[0].name
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding_v1" "ebs_csi_snapshotter_binding" {
  metadata {
    name = "ebs-csi-snapshotter-binding"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.ebs_external_snapshotter_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ebs_csi_controller_sa.metadata[0].name
    namespace = "kube-system"
  }
}

############################
# Deployment: ebs-csi-controller
############################

resource "kubernetes_deployment_v1" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app                          = "ebs-csi-controller"
        "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        # max_unavailable supports int-or-string; "1" is valid
        max_unavailable = "1"
      }
    }

    template {
      metadata {
        labels = {
          app                          = "ebs-csi-controller"
          "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
        }
      }

      spec {
        host_network = true
        dns_policy   = "ClusterFirstWithHostNet"
        priority_class_name = "system-cluster-critical"
        service_account_name = kubernetes_service_account_v1.ebs_csi_controller_sa.metadata[0].name

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
          fs_group        = 1000
        }

        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
        toleration {
          operator           = "Exists"
          effect             = "NoExecute"
          toleration_seconds = 300
        }

        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              preference {
                match_expressions {
                  key      = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate","auto","hybrid"]
                }
              }
            }
          }
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = ["ebs-csi-controller"]
                  }
                }
              }
            }
          }
        }

        volume {
          name = "socket-dir"
          empty_dir {}
        }

        container {
          name  = "ebs-plugin"
          image = "public.ecr.aws/ebs-csi-driver/aws-ebs-csi-driver:v1.49.0"
          image_pull_policy = "IfNotPresent"

          args = [
            "controller","--endpoint=$(CSI_ENDPOINT)","--batching=true",
            "--logging-format=text","--user-agent-extra=kustomize","--v=2"
          ]

          env {
            name  = "CSI_ENDPOINT"
            value = "unix:///var/lib/csi/sockets/pluginproxy/csi.sock"
          }
          env {
            name = "CSI_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "AWS_ACCESS_KEY_ID"
            value_from {
              secret_key_ref {
                name     = "aws-secret"
                key      = "key_id"
                optional = true
              }
            }
          }
          env {
            name = "AWS_SECRET_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name     = "aws-secret"
                key      = "access_key"
                optional = true
              }
            }
          }
          env {
            name = "AWS_EC2_ENDPOINT"
            value_from {
              config_map_key_ref {
                name     = "aws-meta"
                key      = "endpoint"
                optional = true
              }
            }
          }
          env {
            name = "AWS_SAGEMAKER_ENDPOINT"
            value_from {
              config_map_key_ref {
                name     = "aws-meta"
                key      = "sagemaker_endpoint"
                optional = true
              }
            }
          }

          port {
            name           = "healthz"
            container_port = 9808
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 60
            failure_threshold     = 10
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 60
            failure_threshold     = 5
          }

          resources {
            requests = {
              cpu    = "10m"
              memory = "40Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            seccomp_profile {
              type = "RuntimeDefault"
            }
          }

          termination_message_policy = "FallbackToLogsOnError"

          volume_mount {
            name       = "socket-dir"
            mount_path = "/var/lib/csi/sockets/pluginproxy/"
          }
        }

        container {
          name  = "csi-provisioner"
          image = "public.ecr.aws/csi-components/csi-provisioner:v5.3.0-eksbuild.4"
          image_pull_policy = "IfNotPresent"
          args = [
            "--timeout=60s","--csi-address=$(ADDRESS)","--v=2","--feature-gates=Topology=true",
            "--extra-create-metadata","--leader-election=true","--default-fstype=ext4",
            "--kube-api-qps=20","--kube-api-burst=100","--worker-threads=100",
            "--retry-interval-max=30m","--feature-gates=VolumeAttributesClass=true"
          ]
          env {
            name  = "ADDRESS"
            value = "/var/lib/csi/sockets/pluginproxy/csi.sock"
          }
          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            seccomp_profile { type = "RuntimeDefault" }
          }
          termination_message_policy = "FallbackToLogsOnError"
          volume_mount { name = "socket-dir" mount_path = "/var/lib/csi/sockets/pluginproxy/" }
        }

        container {
          name  = "csi-attacher"
          image = "public.ecr.aws/csi-components/csi-attacher:v4.9.0-eksbuild.4"
          image_pull_policy = "IfNotPresent"
          args = [
            "--timeout=6m","--csi-address=$(ADDRESS)","--v=2","--leader-election=true",
            "--kube-api-qps=20","--kube-api-burst=100","--worker-threads=100","--retry-interval-max=5m"
          ]
          env { name = "ADDRESS" value = "/var/lib/csi/sockets/pluginproxy/csi.sock" }
          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            seccomp_profile { type = "RuntimeDefault" }
          }
          termination_message_policy = "FallbackToLogsOnError"
          volume_mount { name = "socket-dir" mount_path = "/var/lib/csi/sockets/pluginproxy/" }
        }

        container {
          name  = "csi-snapshotter"
          image = "public.ecr.aws/csi-components/csi-snapshotter:v8.3.0-eksbuild.2"
          image_pull_policy = "IfNotPresent"
          args = [
            "--csi-address=$(ADDRESS)","--leader-election=true","--v=2","--extra-create-metadata",
            "--kube-api-qps=20","--kube-api-burst=100","--worker-threads=100","--retry-interval-max=30m"
          ]
          env { name = "ADDRESS" value = "/var/lib/csi/sockets/pluginproxy/csi.sock" }
          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            seccomp_profile { type = "RuntimeDefault" }
          }
          termination_message_policy = "FallbackToLogsOnError"
          volume_mount { name = "socket-dir" mount_path = "/var/lib/csi/sockets/pluginproxy/" }
        }

        container {
          name  = "csi-resizer"
          image = "public.ecr.aws/csi-components/csi-resizer:v1.14.0-eksbuild.4"
          image_pull_policy = "IfNotPresent"
          args = [
            "--timeout=60s","--extra-modify-metadata","--csi-address=$(ADDRESS)","--v=2",
            "--handle-volume-inuse-error=false","--leader-election=true","--kube-api-qps=20",
            "--kube-api-burst=100","--workers=100","--retry-interval-max=30m",
            "--feature-gates=VolumeAttributesClass=true"
          ]
          env { name = "ADDRESS" value = "/var/lib/csi/sockets/pluginproxy/csi.sock" }
          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            seccomp_profile { type = "RuntimeDefault" }
          }
          termination_message_policy = "FallbackToLogsOnError"
          volume_mount { name = "socket-dir" mount_path = "/var/lib/csi/sockets/pluginproxy/" }
        }

        container {
          name  = "liveness-probe"
          image = "public.ecr.aws/csi-components/livenessprobe:v2.16.0-eksbuild.5"
          image_pull_policy = "IfNotPresent"
          args = ["--csi-address=/csi/csi.sock","--probe-timeout=60s"]
          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
          termination_message_policy = "FallbackToLogsOnError"
          volume_mount { name = "socket-dir" mount_path = "/csi" }
        }
      }
    }
  }
}

############################
# PodDisruptionBudget
############################

resource "kubernetes_pod_disruption_budget_v1" "ebs_csi_controller_pdb" {
  metadata {
    name      = "ebs-csi-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  spec {
    max_unavailable = "1"
    selector {
      match_labels = {
        app                          = "ebs-csi-controller"
        "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
      }
    }
  }
}

############################
# DaemonSet: ebs-csi-node
############################

resource "kubernetes_daemon_set_v1" "ebs_csi_node" {
  metadata {
    name      = "ebs-csi-node"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }

  spec {
    selector {
      match_labels = {
        app                          = "ebs-csi-node"
        "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
      }
    }

    update_strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "10%"
      }
    }

    template {
      metadata {
        labels = {
          app                          = "ebs-csi-node"
          "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
        }
      }

      spec {
        host_network               = true
        dns_policy                 = "ClusterFirstWithHostNet"
        priority_class_name        = "system-node-critical"
        service_account_name       = kubernetes_service_account_v1.ebs_csi_node_sa.metadata[0].name
        termination_grace_period_seconds = 30

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        toleration { operator = "Exists" }

        security_context {
          run_as_non_root = false
          run_as_user     = 0
          run_as_group    = 0
          fs_group        = 0
        }

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate","auto","hybrid"]
                }
                match_expressions {
                  key      = "node.kubernetes.io/instance-type"
                  operator = "NotIn"
                  values   = ["a1.medium","a1.large","a1.xlarge","a1.2xlarge","a1.4xlarge"]
                }
              }
            }
          }
        }

        # Volumes
        volume { name = "kubelet-dir"      host_path { path = "/var/lib/kubelet"                              type = "Directory" } }
        volume { name = "plugin-dir"       host_path { path = "/var/lib/kubelet/plugins/ebs.csi.aws.com/"     type = "DirectoryOrCreate" } }
        volume { name = "registration-dir" host_path { path = "/var/lib/kubelet/plugins_registry/"            type = "Directory" } }
        volume { name = "device-dir"       host_path { path = "/dev"                                          type = "Directory" } }
        volume { name = "probe-dir"        empty_dir {} }

        # Containers
        container {
          name              = "ebs-plugin"
          image             = "public.ecr.aws/ebs-csi-driver/aws-ebs-csi-driver:v1.49.0"
          image_pull_policy = "IfNotPresent"
          args = [
            "node","--endpoint=$(CSI_ENDPOINT)",
            "--csi-mount-point-prefix=/var/lib/kubelet/plugins/kubernetes.io/csi/ebs.csi.aws.com/",
            "--logging-format=text","--v=2"
          ]
          env { name = "CSI_ENDPOINT" value = "unix:/csi/csi.sock" }
          env {
            name = "CSI_NODE_NAME"
            value_from { field_ref { field_path = "spec.nodeName" } }
          }
          lifecycle {
            pre_stop {
              exec {
                command = ["/bin/aws-ebs-csi-driver","pre-stop-hook"]
              }
            }
          }
          port { name = "healthz" container_port = 9808 protocol = "TCP" }

          liveness_probe {
            http_get { path = "/healthz" port = "healthz" }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 5
          }
          readiness_probe {
            http_get { path = "/healthz" port = "healthz" }
            period_seconds    = 5
            timeout_seconds   = 3
            failure_threshold = 3
          }

          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            privileged                 = true
            read_only_root_filesystem  = true
          }
          termination_message_policy = "FallbackToLogsOnError"

          volume_mount { name = "kubelet-dir"      mount_path = "/var/lib/kubelet"                             mount_propagation = "Bidirectional" }
          volume_mount { name = "plugin-dir"       mount_path = "/csi" }
          volume_mount { name = "device-dir"       mount_path = "/dev" }
        }

        container {
          name              = "node-driver-registrar"
          image             = "public.ecr.aws/csi-components/csi-node-driver-registrar:v2.14.0-eksbuild.5"
          image_pull_policy = "IfNotPresent"
          args = [
            "--csi-address=$(ADDRESS)",
            "--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)",
            "--v=2"
          ]
          env { name = "ADDRESS" value = "/csi/csi.sock" }
          env { name = "DRIVER_REG_SOCK_PATH" value = "/var/lib/kubelet/plugins/ebs.csi.aws.com/csi.sock" }

          liveness_probe {
            exec {
              command = [
                "/csi-node-driver-registrar",
                "--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)",
                "--mode=kubelet-registration-probe"
              ]
            }
            initial_delay_seconds = 30
            period_seconds        = 90
            timeout_seconds       = 15
          }

          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
          termination_message_policy = "FallbackToLogsOnError"

          volume_mount { name = "plugin-dir"       mount_path = "/csi" }
          volume_mount { name = "registration-dir" mount_path = "/registration" }
          volume_mount { name = "probe-dir"        mount_path = "/var/lib/kubelet/plugins/ebs.csi.aws.com/" }
        }

        container {
          name              = "liveness-probe"
          image             = "public.ecr.aws/csi-components/livenessprobe:v2.16.0-eksbuild.5"
          image_pull_policy = "IfNotPresent"
          args              = ["--csi-address=/csi/csi.sock"]
          resources {
            requests = { cpu = "10m", memory = "40Mi" }
            limits   = { memory = "256Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
          termination_message_policy = "FallbackToLogsOnError"
          volume_mount { name = "plugin-dir" mount_path = "/csi" }
        }
      }
    }
  }
}

############################
# CSIDriver
############################

resource "kubernetes_csi_driver_v1" "ebs_csi_driver" {
  metadata {
    name = "ebs.csi.aws.com"
    labels = {
      "app.kubernetes.io/name" = "aws-ebs-csi-driver"
    }
  }
  spec {
    attach_required                         = true
    fs_group_policy                         = "File"
    node_allocatable_update_period_seconds  = 10
    pod_info_on_mount                       = false
  }
}
