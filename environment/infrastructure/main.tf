provider "google" {
  project = local.project
  region  = local.region
}

module "validation" {
  source = "./validation"

  project = nonsensitive(var.vcluster.properties["project"])
  region  = nonsensitive(var.vcluster.properties["region"])
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "google_compute_zones" "available" {
  project = local.project
  region  = local.region
  status  = "UP"
}

module "vpc" {
  for_each = { (local.project_region_key) = true }

  source  = "terraform-google-modules/network/google"
  version = "~> 11.1"

  project_id   = local.project
  network_name = local.vcluster_unique_name

  subnets = [
    {
      subnet_name           = local.public_subnet_name
      subnet_ip             = local.public_subnet_cidr
      subnet_region         = local.region
      subnet_private_access = "true"
    },
    {
      subnet_name           = local.private_subnet_name
      subnet_ip             = local.private_subnet_cidr
      subnet_region         = local.region
      subnet_private_access = "true"
    }
  ]
}

module "cloud_nat" {
  for_each = { (local.project_region_key) = true }

  source  = "terraform-google-modules/cloud-nat/google"
  version = "~> 5.0"

  project_id                         = local.project
  region                             = local.region
  name                               = format("%s-nat", local.vcluster_unique_name)
  router                             = format("%s-router", local.vcluster_unique_name)
  create_router                      = true
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  network                            = module.vpc[local.project_region_key].network_self_link
}
