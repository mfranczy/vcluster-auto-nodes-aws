# Load and split a multi-document YAML file
locals {
  csi_yaml = file("${path.module}/manifests/csi.yaml")
  csi_chunks = split("\n---\n", local.csi_yaml)

  csi_docs = [
    for chunk in local.csi_chunks :
    yamldecode(chunk)
    if trimspace(chunk) != ""
  ]

  csi_map = {
    for i, m in local.csi_docs :
    "${lower(m.kind)}:${lookup(m.metadata, "namespace", "")}:${m.metadata.name}:${i}" => m
  }
}

resource "kubernetes_manifest" "csi" {
  for_each        = local.csi_map
  manifest        = each.value

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
    "spec.nodeAllocatableUpdatePeriodSeconds"
  ]

  field_manager {
    force_conflicts = true
  }

  wait {
    rollout = false
  }
}
