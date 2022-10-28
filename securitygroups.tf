

resource "aws_security_group" "allow-ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.ran_security_4g_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_security_group" "wide-open" {
  name        = "allow_all"
  description = "Allow all traffic"
  vpc_id      = module.ran_security_4g_vpc.id

  ingress {
    description      = "Wide Open"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "wide_open"
  }
}

resource "aws_security_group" "allow_s1ap" {
  name        = "allow_sctp_s1ap"
  description = "Allow SCTP S1AP traffic"
  vpc_id      = module.ran_security_4g_vpc.id

  ingress {
    description      = "SCTP"
    from_port        = 0
    to_port          = 36412
    protocol         = "132"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_sctp_s1ap"
  }
}

#Allow both GTP-C and GTP-U
resource "aws_security_group" "allow_gtp" {
  name        = "allow_gtp"
  description = "Allow GTP traffic"
  vpc_id      = module.ran_security_4g_vpc.id

  ingress {
    description      = "GTP-U"
    from_port        = 0
    to_port          = 2152
    protocol         = "17"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "GTP-C"
    from_port        = 0
    to_port          = 2123
    protocol         = "17"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_gtp"
  }
}

resource "aws_security_group" "allow_ipsec" {
  name        = "allow_ipsec"
  description = "Allow IPSec traffic"
  vpc_id      = module.ran_security_4g_vpc.id

  ingress {
    description      = "IPSec"
    from_port        = 0
    to_port          = 4500
    protocol         = "17"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ISAKAMP"
    from_port        = 0
    to_port          = 500
    protocol         = "17"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "ESP"
    from_port        = 0
    to_port          = 0
    protocol         = "50"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ipsec"
  }
}