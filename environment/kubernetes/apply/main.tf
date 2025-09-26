locals {
  manifest_yaml   = replace(file(var.manifest_file), "\r\n", "\n")
  manifest_chunks = [for c in split("\n---\n", local.manifest_yaml) : c if trimspace(c) != ""]
  manifest_docs   = [for c in local.manifest_chunks : yamldecode(c)]

  # Build a per-doc entry with its own computed_fields
  entries = [
    for i, m in local.manifest_docs : {
      key = "${lower(lookup(m, "kind", ""))}:${lookup(lookup(m, "metadata", {}), "namespace", "")}:${lookup(lookup(m, "metadata", {}), "name", "")}:${i}"
      manifest = m
      # derive keys
      kind = lower(lookup(m, "kind", ""))
      gvk  = "${lower(lookup(m, "apiVersion", ""))}/${lower(lookup(m, "kind", ""))}"
      # pick computed_fields with precedence: GVK > kind > default
      computed_fields = try(
        var.computed_fields_by_gvk[gvk],
        try(var.computed_fields_by_kind[kind], var.computed_fields_default)
      )
    }
  ]

  manifest_map = { for e in local.entries : e.key => e }
}

resource "kubernetes_manifest" "apply" {
  for_each = local.manifest_map
  manifest = each.value.manifest

  wait { rollout = false }
  field_manager { force_conflicts = true }
  computed_fields = each.value.computed_fields
}
