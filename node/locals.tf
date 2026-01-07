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
}
