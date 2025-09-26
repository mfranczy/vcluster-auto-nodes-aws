locals {
  manifest_files = [
    "${path.module}/manifests/admission-policy.yaml",
    "${path.module}/manifests/ccm.yaml",
    "${path.module}/manifests/csi.yaml",
  ]

  computed_fields_by_file = {
    "${path.module}/manifests/csi.yaml" = {
      by_kind = {
        csidriver = ["nodeAllocatableUpdatePeriodSeconds"]
      }
    }
  }

  manifests = {
    for f in local.manifest_files :
    f => {
      file     = f
      default  = try(local.computed_fields_by_file[f].default, [])
      by_kind  = try(local.computed_fields_by_file[f].by_kind, {})
      by_gvk   = try(local.computed_fields_by_file[f].by_gvk, {})
    }
  }
}

module "manifests" {
  source = "./apply"
  for_each = local.manifests

  manifest_file             = each.value.file
  computed_fields_default   = each.value.default
  computed_fields_by_kind   = each.value.by_kind
  computed_fields_by_gvk    = each.value.by_gvk
}
