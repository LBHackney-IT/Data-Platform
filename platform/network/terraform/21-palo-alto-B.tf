resource "aws_network_interface" "FWPublicNetworkInterface-2B" {
  provider          = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0
  description       = "Untrust-interface-2B"
  subnet_id         = module.ss_primary_vpc.public_subnets[1]
  security_groups   = [aws_security_group.UntrustSecurityGroup.id]
  source_dest_check = false
  private_ip        = cidrhost(var.ss_primary_public_subnets[1], 100)

  tags = merge(
    module.tags.values,
    {
      "Name" = "FwUntrust-2B"
    }
  )
}

resource "aws_network_interface" "FWManagementNetworkInterface-2B" {
  provider = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0

  description       = "Management-interface-2B"
  subnet_id         = module.ss_primary_vpc.database_subnets[1]
  security_groups   = [aws_security_group.MgmtSecurityGroup.id]
  source_dest_check = false
  private_ip        = cidrhost(var.ss_primary_mgmt_subnets[1], 99)

  tags = merge(
    module.tags.values,
    {
      "Name" = "FwMgmt-2B"
    }
  )
}

resource "aws_network_interface" "FWPrivate12NetworkInterface-2B" {
  provider = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0

  description       = "Trust-interface-2B"
  subnet_id         = module.ss_primary_vpc.private_subnets[1]
  security_groups   = [aws_security_group.TrustSecurityGroup.id]
  source_dest_check = false
  private_ip        = cidrhost(var.ss_primary_private_subnets[1], 16)


  tags = merge(
    module.tags.values,
    {
      "Name" = "FwTrust-2B"
    }
  )
}


resource "aws_eip" "PublicElasticIP-2B" {
  depends_on = [module.ss_primary_vpc]
  provider   = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0

  vpc = true

  tags = merge(
    module.tags.values,
    {
      "Name" = "Untrust-Eip-2B"
    }
  )
}

resource "aws_eip" "ManagementElasticIP-2B" {
  depends_on = [module.ss_primary_vpc]
  provider   = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0

  vpc = true

  tags = merge(
    module.tags.values,
    {
      "Name" = "Mgmt-Eip-2B"
    }
  )
}


resource "aws_eip_association" "FWEIPManagementAssociation-2B" {
  provider = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0

  network_interface_id =  element(aws_network_interface.FWManagementNetworkInterface-2B.*.id, count.index)
  allocation_id        =  element(aws_eip.ManagementElasticIP-2B.*.id, count.index)
}

resource "aws_eip_association" "FWEIPPublicAssociation-2B" {
  provider = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0

  network_interface_id = element(aws_network_interface.FWPublicNetworkInterface-2B.*.id, count.index)
  allocation_id        = element(aws_eip.PublicElasticIP-2B.*.id, count.index)
}



resource "aws_instance" "FWInstance-2B" {
  provider = aws.ss_primary
  count             =  var.pa_ha ? 1 : 0


  disable_api_termination = false
  iam_instance_profile                 = aws_iam_instance_profile.bootstrap_profile.id
  user_data                            = base64encode(join("", list("vmseries-bootstrap-aws-s3bucket=", aws_s3_bucket.bootstrap_bucket_fw_b.id)))
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
    network_interface_id = element(aws_network_interface.FWPublicNetworkInterface-2B.*.id, count.index)
  }

  network_interface {
    device_index         = 1
    network_interface_id = element(aws_network_interface.FWManagementNetworkInterface-2B.*.id, count.index)
  }

  network_interface {
    device_index         = 2
    network_interface_id = element(aws_network_interface.FWPrivate12NetworkInterface-2B.*.id, count.index)
  }

  tags = merge(
    module.tags.values,
    {
      "Name" = format("Hub-NgFw-B-%s", var.environment)
    }
  )
}
