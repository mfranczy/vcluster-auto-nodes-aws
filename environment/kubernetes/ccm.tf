# ServiceAccount
resource "kubernetes_service_account_v1" "ccm_sa" {
  metadata {
    name      = "cloud-controller-manager"
    namespace = "kube-system"
  }
}

# ClusterRole
resource "kubernetes_cluster_role_v1" "ccm_cluster_role" {
  metadata {
    name = "system:cloud-controller-manager"
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["*"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/status"]
    verbs      = ["patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["services/status"]
    verbs      = ["list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["create", "get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["create", "get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create", "get", "list", "watch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts/token"]
    verbs      = ["create"]
  }
}

# RoleBinding
resource "kubernetes_role_binding_v1" "ccm_apiserver_auth_reader" {
  metadata {
    name      = "cloud-controller-manager:apiserver-authentication-reader"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ccm_sa.metadata[0].name
    namespace = kubernetes_service_account_v1.ccm_sa.metadata[0].namespace
    api_group = ""
  }
}

# ClusterRoleBinding
resource "kubernetes_cluster_role_binding_v1" "ccm_cluster_role_binding" {
  metadata {
    name = "system:cloud-controller-manager"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.ccm_cluster_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ccm_sa.metadata[0].name
    namespace = kubernetes_service_account_v1.ccm_sa.metadata[0].namespace
    api_group = ""
  }
}

# ConfigMap with cloud-config
resource "kubernetes_config_map_v1" "ccm_cloud_config" {
  metadata {
    name      = "aws-cloud-config"
    namespace = "kube-system"
  }

  data = {
    "cloud-config" = <<-EOT
      [Global]
      NLBSecurityGroupMode = Managed
    EOT
  }
}

# Deployment
resource "kubernetes_deployment_v1" "aws_cloud_controller_manager" {
  metadata {
    name      = "aws-cloud-controller-manager"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "aws-cloud-controller-manager"
    }
  }

  wait_for_rollout = false

  spec {
    replicas = 1

    selector {
      match_labels = {
        "k8s-app" = "aws-cloud-controller-manager"
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app" = "aws-cloud-controller-manager"
        }
      }

      spec {
        host_network         = true
        service_account_name = kubernetes_service_account_v1.ccm_sa.metadata[0].name

        container {
          name  = "aws-cloud-controller-manager"
          image = "registry.k8s.io/provider-aws/cloud-controller-manager:v1.34.0"

          args = [
            "--v=2",
            "--cloud-provider=aws",
            "--cloud-config=/etc/kubernetes/cloud-config",
            "--use-service-account-credentials=true",
            "--configure-cloud-routes=false",
          ]

          resources {
            requests = {
              cpu = "200m"
            }
          }

          volume_mount {
            name       = "cloud-config"
            mount_path = "/etc/kubernetes"
            read_only  = true
          }
        }

        volume {
          name = "cloud-config"

          config_map {
            name = kubernetes_config_map_v1.ccm_cloud_config.metadata[0].name

            items {
              key  = "cloud-config"
              path = "cloud-config"
            }
          }
        }

        toleration {
          key      = "node.cloudprovider.kubernetes.io/uninitialized"
          value    = "true"
          effect   = "NoSchedule"
          operator = "Equal"
        }

        toleration {
          key    = "node-role.kubernetes.io/control-plane"
          effect = "NoSchedule"
        }

        toleration {
          key    = "karpenter.sh/unregistered"
          effect = "NoExecute"
        }

        toleration {
          key    = "node.kubernetes.io/not-ready"
          effect = "NoSchedule"
        }
      }
    }
  }
}
