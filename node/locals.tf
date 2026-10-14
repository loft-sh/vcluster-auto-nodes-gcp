locals {
  project = module.validation.project
  region  = module.validation.region
  zone    = module.validation.zone

  # var.vcluster.instance is null for NodeClaims without a vCluster, name and namespace are always set
  vcluster_name      = nonsensitive(var.vcluster.name)
  vcluster_namespace = nonsensitive(var.vcluster.namespace)

  # vCluster names are only unique per namespace and workers share the network environment,
  # so the cluster ID combines both. It must match the CCM --cluster-name flag.
  cluster_id = format("%s-%s", substr(local.vcluster_name, 0, 40), substr(md5(format("%s/%s", local.vcluster_namespace, local.vcluster_name)), 0, 8))

  infrastructure = var.vcluster.networkEnvironment.outputs.infrastructure

  network_name          = nonsensitive(local.infrastructure["network_name"])
  subnet_name           = nonsensitive(local.infrastructure["subnet_name"])
  service_account_email = nonsensitive(local.infrastructure["service_account_email"])

  instance_type = nonsensitive(var.vcluster.nodeType.spec.properties["instance-type"])
}
