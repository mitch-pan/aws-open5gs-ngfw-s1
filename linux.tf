data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
# This VM will run all the packet core elements except the MME
resource "aws_instance" "ubuntu-epc" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  key_name = var.new_ssh_key

  #This interface will act as the S1-U interface
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.ubuntu-s1.id
    //delete_on_termination = true
  }

  #This interface will act as the SGi interface.  Due to AWS routing, it may not always be used for egress traffic
  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.ubuntu-sgi.id
    //delete_on_termination = true
  }

  tags = {
    Name = "ubuntu-epc"
  }
}

# This VM will run the MME
resource "aws_instance" "ubuntu-mme" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"      #This could be altered to use other instance types
  key_name = var.new_ssh_key

  #This will act as the S1-MME and S11 interface
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.ubuntu-mme.id
    //delete_on_termination = true
  }

  tags = {
    Name = "ubuntu-mme"
  }

}


# This VM will run the bastion host
resource "aws_instance" "ubuntu-bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"      # Used t3.small since t3.micro only supports 2 ENIs
  key_name = var.new_ssh_key

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.bastion-public.id
    //delete_on_termination = true
  }

  network_interface {
    device_index = 1
    network_interface_id = aws_network_interface.bastion-private.id
    //delete_on_termination = true
  }

  tags = {
    Name = "ubuntu-bastion"
  }
}

