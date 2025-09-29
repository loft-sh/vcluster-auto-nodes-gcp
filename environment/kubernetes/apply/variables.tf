variable "manifest_file" {
  description = "Path to a templated YAML file (can be multi-doc)."
  type        = string
}

variable "template_vars" {
  description = "Map of placeholders used inside the YAML template."
  type        = map(string)
  default     = {}
}

variable "computed_fields" {
  description = "Computed fields"
  type        = list(string)
  default     = []
}
