# Configure the AWS Provider
provider "aws" {
  #version = "~> 4.21"
  region  = var.region
}

module "vmseries-modules_vmseries" {
  source   = "PaloAltoNetworks/vmseries-modules/aws//modules/vmseries"
  #version = "0.2.0"

  for_each = var.vmseries

  vmseries_version = var.vmseries_version
  name              = var.ngfw_name
  ssh_key_name      = var.new_ssh_key

  # Subnets are defined in security_vpc_subnets variable in terraform.tfvars
  interfaces = {
    ## Deploys 3 DP interfaces on the NGFW, ethernet1/1, ethernet1/2, ehternet1/3
    mgmt = {
      device_index       = 0
      security_group_ids = [module.ran_security_4g_vpc.security_group_ids["vmseries_mgmt"]]
      source_dest_check  = true
      subnet_id          = module.vmseries_subnet_set["mgmt"].subnets[each.value.az].id
      create_public_ip   = true
      private_ips        = ["10.100.0.100"]
    },
    ran = {
      device_index       = 1
      security_group_ids = [aws_security_group.allow_s1ap.id, aws_security_group.allow_gtp.id, aws_security_group.allow_ipsec.id ]
      source_dest_check  = false
      subnet_id          = module.vmseries_subnet_set["ran"].subnets[each.value.az].id
      create_public_ip   = true
      private_ips        = ["10.100.1.5"]
    },
    mme = {
      device_index       = 2
      security_group_ids = [aws_security_group.wide-open.id]
      source_dest_check  = false
      subnet_id          = module.vmseries_subnet_set["mme"].subnets[each.value.az].id
      create_public_ip   = false
      private_ips        = ["10.100.2.5"]
    }
    core = {
      device_index       = 3
      security_group_ids = [aws_security_group.wide-open.id]
      source_dest_check  = false
      subnet_id          = module.vmseries_subnet_set["core"].subnets[each.value.az].id
      create_public_ip   = false
      private_ips        = ["10.100.3.5"]
    }
  }

  bootstrap_options       = "${join("", tolist(["vmseries-bootstrap-aws-s3bucket=", module.panos-bootstrap.bucket_id]))}"
  iam_instance_profile    = module.panos-bootstrap.instance_profile_name

  tags = var.global_tags
}


module "panos-bootstrap" {
  source = "PaloAltoNetworks/vmseries-modules/aws//modules/bootstrap"
  source_root_directory = var.local_bootstrap_directory

  #hostname           = "my-firewall"
  #plugin-op-commands = "dhcp-client;hostname=vms01"

}


