output "network_name" {
  value     = module.vpc[local.project_region_key].network_name
  sensitive = true
}

output "subnet_name" {
  value     = module.vpc[local.project_region_key].subnets["${local.region}/${local.private_subnet_name}"].name
  sensitive = true
}

output "service_account_email" {
  value     = google_service_account.vcluster_node.email
  sensitive = true
}

output "availability_zones" {
  description = "A list of availability zones"
  value       = data.google_compute_zones.available.names
}
