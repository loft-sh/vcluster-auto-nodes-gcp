##########
# CCM
#########

module "kubernetes_apply_ccm" {
  source        = "./apply"

  manifest_file = "${path.module}/manifests/ccm.yaml.tftpl"
  template_vars = {
    network_name  = local.network_name
    subnet_name   = local.subnet_name
    vcluster_name = local.vcluster_name
    node_provider_name = local.node_provider_name
  }
}

##########
# CSI
##########

module "kubernetes_apply_csi" {
  source        = "./apply"

  # The oldest supported k8s versio is 1.30.x, that requires CSI Driver 1.13.x
  manifest_file = "${path.module}/manifests/csi.yaml.tftpl"
  computed_fields = ["globalDefault"]

  template_vars = {
    node_provider_name = local.node_provider_name
  }
}
