resource "google_service_account" "vcluster_node" {
  project      = local.project
  account_id   = format("%s-node", local.vcluster_unique_name)
  display_name = format("vCluster node role for %s", local.vcluster_unique_name)
  description  = "Used by Kubernetes nodes (IMDS tokens) for CCM/CSI"
}

###################
# CCM
###################

resource "google_project_iam_member" "ccm_roles" {
  for_each = local.ccm_enabled ? toset([
    "roles/compute.viewer",
    "roles/compute.loadBalancerAdmin",
    "roles/compute.instanceAdmin.v1",
    "roles/iam.serviceAccountUser",
  ]) : toset([])

  project = local.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.vcluster_node.email}"
}

resource "google_project_iam_custom_role" "ccm_firewall_min" {
  for_each = local.ccm_enabled ? { enabled = true } : {}

  project     = local.project
  role_id     = replace(format("%s-ccm-firewall-min", local.vcluster_unique_name), "-", "_")
  title       = format("%s CCM firewall minimal", local.vcluster_unique_name)
  description = "Minimal VPC firewall permissions for cloud-provider-gcp"
  permissions = [
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.firewalls.update",
    "compute.networks.updatePolicy",
  ]
}

resource "google_project_iam_member" "ccm_firewall_binding" {
  for_each = local.ccm_enabled ? { enabled = true } : {}

  project = local.project
  role    = google_project_iam_custom_role.ccm_firewall_min[each.key].name
  member  = "serviceAccount:${google_service_account.vcluster_node.email}"
}

###################
# CSI
###################

resource "google_project_iam_member" "csi_roles" {
  for_each = local.csi_enabled ? toset([
    "roles/compute.viewer",
    "roles/compute.storageAdmin",
    "roles/iam.serviceAccountUser",
  ]) : toset([])

  project = local.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.vcluster_node.email}"
}
