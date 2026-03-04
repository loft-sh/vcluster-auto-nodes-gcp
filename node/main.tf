provider "google" {
  project = local.project
  region  = local.region
}

module "validation" {
  source = "./validation"

  project = nonsensitive(var.vcluster.properties["project"])
  region  = nonsensitive(var.vcluster.properties["region"])
  zone    = try(nonsensitive(var.vcluster.properties["zone"]), "")
}

resource "random_id" "vm_suffix" {
  byte_length = 4
}

module "private_instance" {
  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "~> 13.6.0"

  region            = local.region
  zone              = local.zone == "" ? null : local.zone
  subnetwork        = local.subnet_name
  num_instances     = 1
  hostname          = "${var.vcluster.name}-${random_id.vm_suffix.hex}"
  instance_template = module.instance_template.self_link

  # Will use NAT
  access_config = []

  labels = {
    vcluster  = local.vcluster_name
    namespace = local.vcluster_namespace

    # the same as the value set in CCM's --cluster-name flag
    cluster-name = local.vcluster_name
  }
}

data "google_project" "project" {
  project_id = local.project
}

# CPU nodes use Ubuntu 24.04 LTS
data "google_compute_image" "cpu" {
  count   = local.is_gpu_node ? 0 : 1
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

# GPU nodes use Deep Learning VM with pre-installed NVIDIA drivers
data "google_compute_image" "gpu" {
  count   = local.is_gpu_node ? 1 : 0
  family  = "common-cu128-ubuntu-2404-nvidia-570"
  project = "deeplearning-platform-release"
}

locals {
  image = local.is_gpu_node ? data.google_compute_image.gpu[0] : data.google_compute_image.cpu[0]
}

module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 13.6.0"

  region             = local.region
  project_id         = local.project
  network            = local.network_name
  subnetwork         = local.subnet_name
  subnetwork_project = local.project
  tags               = ["allow-iap-ssh", local.vcluster_name] # for IAP SSH access

  machine_type = local.instance_type

  source_image         = local.image.self_link
  source_image_family  = local.image.family
  source_image_project = local.image.project

  disk_size_gb = local.disk_size
  disk_type    = "pd-standard"

  gpu                 = local.gpu_config
  on_host_maintenance = local.on_host_maintenance

  service_account = {
    email  = local.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    user-data = var.vcluster.userData != "" ? var.vcluster.userData : null
  }

  startup_script = "#!/bin/bash\n# Ensure cloud-init runs\ncloud-init status --wait || true"
}
