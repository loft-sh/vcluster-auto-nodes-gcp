locals {
  project = module.validation.project
  region  = module.validation.region
  zone    = module.validation.zone

  vcluster_name      = nonsensitive(var.vcluster.instance.metadata.name)
  vcluster_namespace = nonsensitive(var.vcluster.instance.metadata.namespace)

  network_name          = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["network_name"])
  subnet_name           = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["subnet_name"])
  service_account_email = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["service_account_email"])

  instance_type = nonsensitive(var.vcluster.nodeType.spec.properties["instance-type"])

  # GPU properties from node type
  gpu_type  = try(nonsensitive(var.vcluster.nodeType.spec.properties["gpu-type"]), "")
  gpu_count = try(tonumber(nonsensitive(var.vcluster.nodeType.spec.properties["gpu-count"])), 0)
  disk_size = try(tonumber(nonsensitive(var.vcluster.nodeType.spec.properties["disk-size"])), 100)

  # G2 (L4), A2 (A100), A3 (H100) have built-in GPUs — no guest_accelerator needed
  has_builtin_gpu = can(regex("^(g2|a2|a3)-", local.instance_type))

  # True if this node needs GPU support (either explicit gpu-type or built-in GPU family)
  is_gpu_node = local.gpu_type != "" || local.has_builtin_gpu

  # guest_accelerator config — only for N1 + T4 style (explicit gpu-type); null for built-in GPU families
  gpu_config = local.gpu_type != "" ? {
    type  = local.gpu_type
    count = local.gpu_count > 0 ? local.gpu_count : 1
  } : null

  # GPU instances must use TERMINATE; CPU instances can live-migrate
  on_host_maintenance = local.is_gpu_node ? "TERMINATE" : "MIGRATE"
}
