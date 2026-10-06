locals {
  project            = module.validation.project
  region             = module.validation.region
  project_region_key = format("%s-%s", local.project, local.region)

  # The network environment is cluster-scoped and shared by every vCluster that uses it
  network_environment_name = nonsensitive(var.vcluster.name)

  # A random_id resource cannot be used here because of how the VPC module applies resources.
  # The module needs resource names to be known in advance.
  random_id = substr(md5(local.network_environment_name), 0, 8)

  public_subnet_name  = format("public-%s", local.random_id)
  private_subnet_name = format("private-%s", local.random_id)

  vpc_cidr   = nonsensitive(try(var.vcluster.properties["vcluster.com/vpc-cidr"], "10.10.0.0/16"))
  vpc_prefix = nonsensitive(tonumber(element(split("/", local.vpc_cidr), 1)))
  subnet_prefix = nonsensitive(
    tonumber(
      try(var.vcluster.properties["vcluster.com/subnet_prefix"], "24")
    )
  )
  public_subnet_cidr  = cidrsubnet(local.vpc_cidr, local.subnet_prefix - local.vpc_prefix, 0)
  private_subnet_cidr = cidrsubnet(local.vpc_cidr, local.subnet_prefix - local.vpc_prefix, 1)

  ccm_enabled = nonsensitive(try(tobool(var.vcluster.properties["vcluster.com/ccm-enabled"]), true))
  csi_enabled = nonsensitive(try(tobool(var.vcluster.properties["vcluster.com/csi-enabled"]), true))
}
