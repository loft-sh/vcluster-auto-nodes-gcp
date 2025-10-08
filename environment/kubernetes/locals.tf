locals {
  network_name  = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["network_name"])
  subnet_name   = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["subnet_name"])
  vcluster_name = nonsensitive(var.vcluster.instance.metadata.name)
  node_provider_name = nonsensitive(var.vcluster.nodeProvider.metadata.name)
}
