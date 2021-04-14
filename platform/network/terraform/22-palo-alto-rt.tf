resource "aws_route" "fromTGW_spokes_standalone" {
  depends_on = [module.ss_primary_vpc]
  count      = var.pa_ha && length(module.ss_primary_vpc.redshift_route_table_ids) > 0 ? 0 : 1
  provider   = aws.ss_primary

  route_table_id         = module.ss_primary_vpc.redshift_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  network_interface_id   = aws_network_interface.FWPrivate12NetworkInterface-2A.id


  timeouts {
    create = "5m"
  }
}

resource "aws_route" "fromTGW_spokes_HA" {
  depends_on = [module.ss_primary_vpc]
  count      = var.pa_ha && length(module.ss_primary_vpc.redshift_route_table_ids) > 0 ? 1 : 0
  provider   = aws.ss_primary

  route_table_id         = module.ss_primary_vpc.redshift_route_table_ids[count.index]
  destination_cidr_block = "10.0.0.0/8"
  network_interface_id   = element(aws_network_interface.FWPrivate12NetworkInterface-2B.*.id, count.index)


  timeouts {
    create = "5m"
  }
}

resource "aws_route" "fromTGW_internet_standalone" {
  depends_on = [module.ss_primary_vpc]
  count      = length(module.ss_primary_vpc.redshift_route_table_ids)
  provider   = aws.ss_primary

  route_table_id         = module.ss_primary_vpc.redshift_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.FWPrivate12NetworkInterface-2A.id

  timeouts {
    create = "5m"
  }
}

