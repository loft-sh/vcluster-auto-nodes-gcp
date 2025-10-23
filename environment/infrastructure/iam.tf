resource "google_service_account" "vcluster_node" {
  project      = local.project
  account_id   = format("vcluster-node-sa-%s", local.random_id)
  display_name = format("Node service account for %s", local.vcluster_name)
  description  = format("Needed by Kubernetes nodes to obtain IMDS tokens for CCM/CSI, used by %s", local.vcluster_name)
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
  role_id     = replace(format("ccm-firewall-%s", local.random_id), "-", "_")
  title       = format("CCM firewall for %s", local.vcluster_name)
  description = format("Minimal VPC firewall permissions for CCM, used by %s", local.vcluster_name)
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
