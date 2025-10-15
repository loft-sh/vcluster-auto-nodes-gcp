locals {
  rendered_yaml = templatefile(var.manifest_file, var.template_vars)

  manifest_yaml   = replace(local.rendered_yaml, "\r\n", "\n")
  manifest_chunks = [for c in split("\n---\n", local.manifest_yaml) : trimspace(c)]
  manifest_docs   = [for c in local.manifest_chunks : yamldecode(c) if c != ""]

  manifest_map = {
    for i, m in local.manifest_docs :
    "${lower(lookup(m, "kind", ""))}:${lookup(lookup(m, "metadata", {}), "namespace", "")}:${lookup(lookup(m, "metadata", {}), "name", "")}:${i}" => m
  }
}

resource "kubernetes_manifest" "apply" {
  for_each = local.manifest_map
  manifest = each.value

  wait { rollout = false }

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }

  computed_fields = concat([
    "metadata.annotations",
    "metadata.labels",
    "metadata.clusterName",
    "metadata.creationTimestamp",
    "metadata.deletionGracePeriodSeconds",
    "metadata.deletionTimestamp",
    "metadata.finalizers",
    "metadata.generateName",
    "metadata.generation",
    "metadata.managedFields",
    "metadata.ownerReferences",
    "metadata.resourceVersion",
    "metadata.uid",
    "status",
  ],
  var.computed_fields,
  )
}
