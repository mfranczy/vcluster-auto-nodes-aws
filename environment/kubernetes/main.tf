locals {
  manifest_files = [
    "${path.module}/manifests/ccm.yaml",
    "${path.module}/manifests/csi.yaml",
  ]
}

module "manifests" {
  source        = "./apply"
  for_each      = toset(local.manifest_files)
  manifest_file = each.value
}
