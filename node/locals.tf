locals {
  project = module.validation.project
  region  = module.validation.region
  zone    = module.validation.zone

  vcluster_name      = nonsensitive(var.vcluster.instance.metadata.name)
  vcluster_namespace = nonsensitive(var.vcluster.instance.metadata.namespace)

  infrastructure = var.vcluster.networkEnvironment.outputs.infrastructure

  network_name          = nonsensitive(local.infrastructure["network_name"])
  subnet_name           = nonsensitive(local.infrastructure["subnet_name"])
  service_account_email = nonsensitive(local.infrastructure["service_account_email"])

  instance_type = nonsensitive(var.vcluster.nodeType.spec.properties["instance-type"])
}
