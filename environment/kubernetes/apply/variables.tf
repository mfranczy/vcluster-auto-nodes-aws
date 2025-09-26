variable "manifest_file" {
  type        = string
  description = "Path to a YAML file with one or more docs (--- separated)."
}

# Optional: default list used when no specific mapping matches
variable "computed_fields_default" {
  type        = list(string)
  default     = [metadata.annotations, metadata.labels]
}

# Optional: per-Kind mapping, keys like "deployment", "daemonset", "service", etc. (lowercased)
variable "computed_fields_by_kind" {
  type        = map(list(string))
  default     = {}
}

# Optional: per-GroupVersionKind mapping, keys like "apps/v1/deployment", "v1/service"
variable "computed_fields_by_gvk" {
  type        = map(list(string))
  default     = {}
}
