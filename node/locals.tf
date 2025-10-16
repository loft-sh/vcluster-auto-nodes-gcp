locals {
  project = module.validation.project
  region  = module.validation.region
  zone    = module.validation.zone

  vcluster_name      = var.vcluster.instance.metadata.name
  vcluster_namespace = var.vcluster.instance.metadata.namespace

  network_name          = var.vcluster.nodeEnvironment.outputs.infrastructure["network_name"]
  subnet_name           = var.vcluster.nodeEnvironment.outputs.infrastructure["subnet_name"]
  service_account_email = var.vcluster.nodeEnvironment.outputs.infrastructure["service_account_email"]

  instance_type = var.vcluster.nodeType.spec.properties["instance-type"]
}
