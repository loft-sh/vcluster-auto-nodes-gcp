locals {
  project            = module.validation.project
  region             = module.validation.region
  project_region_key = format("%s-%s", local.project, local.region)

  vcluster_name      = nonsensitive(var.vcluster.instance.metadata.name)
  vcluster_namespace = nonsensitive(var.vcluster.instance.metadata.namespace)

  # A random_id resource cannot be used here because of how the VPC module applies resources.
  # The module needs resource names to be known in advance.
  random_id            = substr(md5(format("%s%s", local.vcluster_namespace, local.vcluster_name)), 0, 8)
  vcluster_unique_name = format("%s-%s", local.vcluster_name, local.random_id)

  public_subnet_name  = format("%s-public", local.vcluster_unique_name)
  private_subnet_name = format("%s-private", local.vcluster_unique_name)

  public_subnet_cidr  = try(var.vcluster.properties["vcluster.com/public-subnet-cidr"], "10.10.2.0/24")
  private_subnet_cidr = try(var.vcluster.properties["vcluster.com/private-subnet-cidr"], "10.10.1.0/24")

  ccm_enabled = try(tobool(var.vcluster.properties["vcluster.com/ccm-enabled"]), true)
  csi_enabled = try(tobool(var.vcluster.properties["vcluster.com/csi-enabled"]), true)
}
