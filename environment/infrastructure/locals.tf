locals {
  project            = module.validation.project
  region             = module.validation.region
  project_region_key = format("%s-%s", local.project, local.region)

  vcluster_name      = nonsensitive(var.vcluster.instance.metadata.name)
  vcluster_namespace = nonsensitive(var.vcluster.instance.metadata.namespace)

  # A random_id resource cannot be used here because of how the VPC module applies resources.
  # The module needs resource names to be known in advance.
  random_id = substr(md5(format("%s%s", local.vcluster_namespace, local.vcluster_name)), 0, 8)

  public_subnet_name  = format("public-%s", local.random_id)
  private_subnet_name = format("private-%s", local.random_id)

  vpc_cidr            = try(var.vcluster.properties["vcluster.com/vpc-cidr"], "10.10.0.0/16")
  vpc_prefix          = tonumber(element(split("/", local.vpc_cidr), 1))
  subnet_prefix       = tonumber(try(var.vcluster.properties["vcluster.com/subnet_prefix"], "24"))
  public_subnet_cidr  = cidrsubnet(local.vpc_cidr, local.subnet_prefix - local.vpc_prefix, 0)
  private_subnet_cidr = cidrsubnet(local.vpc_cidr, local.subnet_prefix - local.vpc_prefix, 1)

  ccm_enabled = try(tobool(var.vcluster.properties["vcluster.com/ccm-enabled"]), true)
  csi_enabled = try(tobool(var.vcluster.properties["vcluster.com/csi-enabled"]), true)
}
