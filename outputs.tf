output "FirewallManagementSSHAccess" {
  value = join("", ["ssh -i ", local_file.ngfw_private_key.filename, " admin@", module.vmseries-modules_vmseries["vmseries01"].public_ips["mgmt"]] )
}

output "BastionManagementSSHAccess" {
  value = join("", ["ssh -i ", local_file.ngfw_private_key.filename, " ubuntu@", aws_eip.bastion-public-ip.public_ip ] )
}

output "WebUIAccess" {
  value = join("", ["https://", module.vmseries-modules_vmseries["vmseries01"].public_ips["mgmt"]]   )
}

output "bucket_id" {
  value       = module.panos-bootstrap.bucket_name
  description = "ID of created bucket."
}