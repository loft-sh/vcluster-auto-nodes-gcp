locals {
  network_name       = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["network_name"])
  subnet_name        = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["subnet_name"])
  vcluster_name      = nonsensitive(var.vcluster.instance.metadata.name)
  node_provider_name = nonsensitive(var.vcluster.nodeProvider.metadata.name)

  ccm_enabled    = try(tobool(var.vcluster.properties["vcluster.com/ccm-enabled"]), true)
  ccm_lb_enabled = try(tobool(var.vcluster.properties["vcluster.com/ccm-lb-enabled"]), true)
  csi_enabled    = try(tobool(var.vcluster.properties["vcluster.com/csi-enabled"]), true)
}
