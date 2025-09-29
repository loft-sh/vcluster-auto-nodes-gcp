output "network_name" {
  value = local.vpc_name
  sensitive = true
}

output "subnet_name" {
  value = module.vpc.subnets["${local.region}/${local.private_subnet_name}"].name
  sensitive = true
}

output "service_account_email" {
  value = google_service_account.ccm_csi.email
  sensitive = true
}
