locals {
  node_provider_name = nonsensitive(var.vcluster.nodeProvider.metadata.name)

  manifest_files = [
    "${path.module}/manifests/admission-policy.yaml.tftpl",
    "${path.module}/manifests/ccm.yaml.tftpl",
    "${path.module}/manifests/csi.yaml.tftpl",
  ]

  files_indexed = { for i, f in local.manifest_files : i => f }
}

module "kubernetes_apply_manifests" {
  source        = "./apply"
  for_each      = local.files_indexed
  manifest_file = each.value
  template_vars = {
    node_provider_name = local.node_provider_name
  }
}

# CSI driver plugin objects are cluster-scoped.
# Because this cluster may run across multiple clouds (or multiple deployments of the same provider),
# it's safer to disable deletion of the CSIDriver to avoid breaking other workloads.
# This is a reason why it is kept as a separate resource definition with prevent_destroy = true.
resource "kubernetes_manifest" "csi_register" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "CSIDriver"
    metadata = {
      name   = "ebs.csi.aws.com"
      labels = {
        "app.kubernetes.io/name" = format("%s-ebs-csi-driver", local.node_provider_name)
      }
    }
    spec = {
      attachRequired = true
      fsGroupPolicy  = "File"
      podInfoOnMount = false
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  wait {
    rollout = false
  }

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}
