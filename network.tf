
#Create the VPC we will use for deployment/testing
module "ran_security_4g_vpc" {
  source = "PaloAltoNetworks/vmseries-modules/aws//modules/vpc"
  #version = "0.2.0"

  name                    = var.security_vpc_name
  cidr_block              = var.security_vpc_cidr
  security_groups         = var.security_vpc_security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
  secondary_cidr_blocks   = ["10.45.0.0/16"] #Necessary to allow the UE traffic

}

module "vmseries_subnet_set" {
  source = "PaloAltoNetworks/vmseries-modules/aws//modules/subnet_set"
  #version = "0.2.0"

  for_each = toset(distinct([for _, v in var.security_vpc_subnets : v.set]))

  name                = each.key
  vpc_id              = module.ran_security_4g_vpc.id
  has_secondary_cidrs = module.ran_security_4g_vpc.has_secondary_cidrs
  cidrs               = { for k, v in var.security_vpc_subnets : k => v if v.set == each.key }
}

resource "aws_network_interface" "ubuntu-s1" {
  subnet_id       = module.vmseries_subnet_set["core"].subnets["us-west-1a"].id
  private_ips     = ["10.100.3.20"]
  security_groups = [aws_security_group.wide-open.id]
  source_dest_check = false

  tags = {
    Name = "ubuntu-epc-s1"
  }
}

resource "aws_network_interface" "ubuntu-sgi" {
  subnet_id       = module.vmseries_subnet_set["sgi"].subnets["us-west-1a"].id
  private_ips     = ["10.100.4.20"]
  security_groups = [aws_security_group.wide-open.id]
  source_dest_check = false

  tags = {
    Name = "ubuntu-epc-sgi"
  }
}

resource "aws_network_interface" "ubuntu-mme" {
  subnet_id       = module.vmseries_subnet_set["mme"].subnets["us-west-1a"].id
  private_ips     = ["10.100.2.20"]
  security_groups = [aws_security_group.wide-open.id]
  source_dest_check = false

  tags = {
    Name = "ubuntu-mme-eni"
  }
}

resource "aws_network_interface" "bastion-public" {
  subnet_id       = module.vmseries_subnet_set["mgmt"].subnets["us-west-1a"].id
  private_ips     = ["10.100.0.50"]
  security_groups = [aws_security_group.allow-ssh.id]

  tags = {
    Name = "bastion-public-eni"
  }
}

resource "aws_network_interface" "bastion-private" {
  subnet_id       = module.vmseries_subnet_set["core"].subnets["us-west-1a"].id
  private_ips     = ["10.100.3.50"]
  security_groups = [aws_security_group.allow-ssh.id]

  tags = {
    Name = "bastion-private-eni"
  }
}

resource "aws_eip" "bastion-public-ip" {
  //vpc = true
  network_interface = aws_network_interface.bastion-public.id
  #depends_on                = [aws_internet_gateway.gw]

  tags = {
    Name = "bastion-public-eip"
  }
}

#Here we use the Palo Alto Networks module to create a NAT GW
module "nat_gateway_set" {
  source = "PaloAltoNetworks/vmseries-modules/aws//modules/nat_gateway_set"

  subnets = module.vmseries_subnet_set["mgmt"].subnets

  nat_gateway_tags = {
    Name = "core-nat-gw"
  }
}


module "vpc_route" {
  source   = "PaloAltoNetworks/vmseries-modules/aws//modules/vpc_route"

  for_each = {
    mgmt = {
      route_table_ids = module.vmseries_subnet_set["mgmt"].unique_route_table_ids
      next_hop_set    = module.ran_security_4g_vpc.igw_as_next_hop_set
      to_cidr         = "0.0.0.0/0"
    }
    ran = {
      route_table_ids = module.vmseries_subnet_set["ran"].unique_route_table_ids
      next_hop_set    = module.ran_security_4g_vpc.igw_as_next_hop_set
      to_cidr         = "0.0.0.0/0"
    }
    ran-to-mme = {
      route_table_ids = module.vmseries_subnet_set["ran"].unique_route_table_ids
      next_hop_set = {
        type = "interface"
        id   = null
          ids  = {
            "us-west-1a" = module.vmseries-modules_vmseries["vmseries01"].interfaces["ran"].id
          }
      }
      to_cidr         = "10.100.2.0/24"
    }
    mme-to-ran = {
      route_table_ids = module.vmseries_subnet_set["mme"].unique_route_table_ids
      next_hop_set = {
        type = "interface"
        id   = null
          ids  = {
            "us-west-1a" = module.vmseries-modules_vmseries["vmseries01"].interfaces["mme"].id
          }
      }
      to_cidr         = "10.100.1.0/24"
    }
    mme-to-core = {
      route_table_ids = module.vmseries_subnet_set["mme"].unique_route_table_ids
      next_hop_set = {
        type = "interface"
        id   = null
          ids  = {
            "us-west-1a" = module.vmseries-modules_vmseries["vmseries01"].interfaces["mme"].id
          }
      }
      to_cidr         = "10.100.3.0/24"
    }
    core-to-mme = {
      route_table_ids = module.vmseries_subnet_set["core"].unique_route_table_ids
      next_hop_set = {
        type = "interface"
        id   = null
          ids  = {
            "us-west-1a" = module.vmseries-modules_vmseries["vmseries01"].interfaces["core"].id
          }
      }
      to_cidr         = "10.100.2.0/24"
    }
    core-to-internet = {
      route_table_ids = module.vmseries_subnet_set["core"].unique_route_table_ids
      next_hop_set    = module.nat_gateway_set.next_hop_set
      to_cidr         = "0.0.0.0/0"
    }
    sgi-to-internet = {
      route_table_ids = module.vmseries_subnet_set["sgi"].unique_route_table_ids
      next_hop_set    = module.nat_gateway_set.next_hop_set
      to_cidr         = "0.0.0.0/0"
    }
    mme-to-enodeb = {
      route_table_ids = module.vmseries_subnet_set["mme"].unique_route_table_ids
      next_hop_set = {
        type = "interface"
        id   = null
          ids  = {
            "us-west-1a" = module.vmseries-modules_vmseries["vmseries01"].interfaces["mme"].id
          }
      }
      to_cidr         = "192.168.1.0/24"
    }
    sgw-to-enodeb = {
      route_table_ids = module.vmseries_subnet_set["core"].unique_route_table_ids
      next_hop_set = {
        type = "interface"
        id   = null
          ids  = {
            "us-west-1a" = module.vmseries-modules_vmseries["vmseries01"].interfaces["core"].id
          }
      }
      to_cidr         = "192.168.1.0/24"
    }

  }

  route_table_ids = each.value.route_table_ids
  next_hop_set    = each.value.next_hop_set
  to_cidr         = each.value.to_cidr
}


