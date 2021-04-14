resource "aws_network_interface" "FWPublicNetworkInterface-2A" {
  provider = aws.ss_primary

  description       = "Untrust-interface-2A"
  subnet_id         = module.ss_primary_vpc.public_subnets[0]
  security_groups   = [aws_security_group.UntrustSecurityGroup.id]
  source_dest_check = false
  private_ip        = cidrhost(var.ss_primary_public_subnets[0], 100)

  tags = merge(
    module.tags.values,
    {
      "Name" = "FwUntrust-2A"
    }
  )
}

resource "aws_network_interface" "FWManagementNetworkInterface-2A" {
  provider = aws.ss_primary

  description       = "Management-interface-2A"
  subnet_id         = module.ss_primary_vpc.database_subnets[0]
  security_groups   = [aws_security_group.MgmtSecurityGroup.id]
  source_dest_check = false
  private_ip        = cidrhost(var.ss_primary_mgmt_subnets[0], 99)

  tags = merge(
    module.tags.values,
    {
      "Name" = "FwMgmt-2A"
    }
  )
}

resource "aws_network_interface" "FWPrivate12NetworkInterface-2A" {
  provider = aws.ss_primary
  # count             =  var.pa_ha ? 1 : 0

  description       = "Trust-interface-2A"
  subnet_id         = module.ss_primary_vpc.private_subnets[0]
  security_groups   = [aws_security_group.TrustSecurityGroup.id]
  source_dest_check = false
  private_ip        = cidrhost(var.ss_primary_private_subnets[0], 16)


  tags = merge(
    module.tags.values,
    {
      "Name" = "FwTrust-2A"
    }
  )
}


resource "aws_eip" "PublicElasticIP-2A" {
  depends_on = [module.ss_primary_vpc]
  provider   = aws.ss_primary

  vpc = true

  tags = merge(
    module.tags.values,
    {
      "Name" = "Untrust-Eip-2A"
    }
  )
}

resource "aws_eip" "ManagementElasticIP-2A" {
  depends_on = [module.ss_primary_vpc]
  provider   = aws.ss_primary

  vpc = true

  tags = merge(
    module.tags.values,
    {
      "Name" = "Mgmt-Eip-2A"
    }
  )
}


resource "aws_eip_association" "FWEIPManagementAssociation-2A" {
  provider = aws.ss_primary

  network_interface_id = aws_network_interface.FWManagementNetworkInterface-2A.id
  allocation_id        = aws_eip.ManagementElasticIP-2A.id
}

resource "aws_eip_association" "FWEIPPublicAssociation-2A" {
  provider = aws.ss_primary

  network_interface_id = aws_network_interface.FWPublicNetworkInterface-2A.id
  allocation_id        = aws_eip.PublicElasticIP-2A.id
}



resource "aws_instance" "FWInstance-2A" {
  provider = aws.ss_primary


  disable_api_termination = false
  iam_instance_profile                 = aws_iam_instance_profile.bootstrap_profile.id
  user_data                            = base64encode(join("", list("vmseries-bootstrap-aws-s3bucket=", aws_s3_bucket.bootstrap_bucket_fw_a.id)))

  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true
  ami                                  = var.PANFWRegionMap[var.ss_primary_region]
  instance_type                        = var.instance_type
  hibernation                          = false

  root_block_device {
    delete_on_termination = false
    volume_size           = 60
    volume_type           = "gp2"
  }
  key_name   = aws_key_pair.generated_key.key_name
  monitoring = false

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.FWPublicNetworkInterface-2A.id
  }

  network_interface {
    device_index         = 1
    network_interface_id = aws_network_interface.FWManagementNetworkInterface-2A.id
  }

  network_interface {
    device_index         = 2
    network_interface_id = aws_network_interface.FWPrivate12NetworkInterface-2A.id
  }


  tags = merge(
    module.tags.values,
    {
      "Name" = format("Hub-NgFw-A-%s", var.environment)
    }
  )
}
