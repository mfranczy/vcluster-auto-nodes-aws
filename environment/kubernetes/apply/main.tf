locals {
  # Read and normalize newlines
  manifest_yaml   = replace(file(var.manifest_file), "\r\n", "\n")
  manifest_chunks = [
    for chunk in split("\n---\n", local.manifest_yaml) :
    chunk if trimspace(chunk) != ""
  ]

  manifest_docs = [
    for chunk in local.manifest_chunks : yamldecode(chunk)
  ]

  # Stable keys: kind:namespace:name:index
  manifest_map = {
    for i, m in local.manifest_docs :
    "${lower(lookup(m, "kind", ""))}:${lookup(lookup(m, "metadata", {}), "namespace", "")}:${lookup(lookup(m, "metadata", {}), "name", "")}:${i}" => m
  }
}

resource "kubernetes_manifest" "apply" {
  for_each = local.manifest_map
  manifest = each.value

  # keep it simple: don't wait for rollouts here
  wait { rollout = false }

  # make server-side apply tolerant when stuff already exists
  field_manager { force_conflicts = true }

  computed_fields = [
    "metadata.annotations",
    "metadata.labels",
    "spec.nodeAllocatableUpdatePeriodSeconds"
  ]
}
