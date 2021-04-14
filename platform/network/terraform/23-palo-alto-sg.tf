resource "aws_security_group" "VPCSecurityGroup" {
  provider    = aws.ss_primary
  name        = "VPCSecurityGroup"
  description = "Security Group for within the VPC"
  vpc_id      = module.ss_primary_vpc.vpc_id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    module.tags.values,
    {
      "Name" = "VPCSecurityGroup"
    }
  )
}

resource "aws_security_group" "MgmtSecurityGroup" {
  provider = aws.ss_primary

  name        = "MgmtSecurityGroup"
  description = "Enable SSH into MGMT interface"
  vpc_id      = module.ss_primary_vpc.vpc_id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = var.SSHLocation
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = var.SSHLocation
  }

  //  ingress {
  //    from_port   = "0"
  //    to_port     = "0"
  //    protocol    = "-1"
  //    cidr_blocks = [var.VPCCIDR]
  //  }
  //
  //  ingress {
  //    from_port   = "22"
  //    to_port     = "22"
  //    protocol    = "tcp"
  //    cidr_blocks = [var.VPCCIDR]
  //  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    module.tags.values,
    {
      "Name" = "MgmtSecurityGroup"
    }
  )
}

resource "aws_security_group" "UntrustSecurityGroup" {
  provider = aws.ss_primary

  name        = "UntrustSecurityGroup"
  description = "Security Group for untrust interface"
  vpc_id      = module.ss_primary_vpc.vpc_id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    module.tags.values,
    {
      "Name" = "UntrustSecurityGroup"
    }
  )
}

resource "aws_security_group" "TrustSecurityGroup" {
  provider = aws.ss_primary

  name        = "TrustSecurityGroup"
  description = "Security Group for trust interface"
  vpc_id      = module.ss_primary_vpc.vpc_id

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    module.tags.values,
    {
      "Name" = "TrustSecurityGroup"
    }
  )
}

