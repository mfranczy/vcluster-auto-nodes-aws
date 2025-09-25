# Load and split a multi-document YAML file
locals {
  csi_yaml = file("${path.module}/manifests/csi.yaml")

  csi_docs = [
    for m in regexall("(?s)^(?:---\\s*)?(.*?)(?=\\n---|\\Z)", local.csi_yaml) :
    yamldecode(m[0])
    if trimspace(m[0]) != ""
  ]

  csi_map = {
    for i, m in local.csi_docs :
    "${lower(m.kind)}:${lookup(m.metadata, "namespace", "")}:${m.metadata.name}:${i}" => m
  }
}

resource "kubernetes_manifest" "csi" {
  for_each        = local.csi_map
  manifest        = each.value
  field_manager   = "terraform"
  force_conflicts = true

  wait {
    rollout = false
  }
}
