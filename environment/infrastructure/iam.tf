############
# CCM / CSI
############

resource "google_service_account" "ccm_csi" {
  project      = local.project
  account_id   = format("%s-ccm-csi", local.vcluster_name)
  display_name = format("CCM/CSI role for %s", local.vcluster_name)
  description  = "Used by Kubernetes nodes (IMDS tokens) for CCM/CSI"
}

resource "google_project_iam_member" "ccm_csi" {
  for_each = toset([
    "roles/compute.viewer",
    "roles/compute.loadBalancerAdmin",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.storageAdmin",
    "roles/iam.serviceAccountUser"
  ])

  project = local.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.ccm_csi.email}"
}

resource "google_project_iam_custom_role" "ccm_firewall_min" {
  project     = local.project
  role_id     = replace(format("%s-ccm-firewall-min", local.vcluster_name), "-", "_")
  title       = format("%s CCM Firewall Minimal", local.vcluster_name)
  description = "Minimal VPC firewall permissions for cloud-provider-gcp"
  permissions = [
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.firewalls.update",
    "compute.networks.updatePolicy"
  ]
}

resource "google_project_iam_member" "ccm_firewall_min" {
  project = local.project
  role    = google_project_iam_custom_role.ccm_firewall_min.id
  member  = "serviceAccount:${google_service_account.ccm_csi.email}"
}
