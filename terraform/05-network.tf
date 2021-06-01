data "aws_vpc" "network" {
  id = var.aws_vpc_id
}

data "aws_subnet_ids" "network" {
  vpc_id = var.aws_vpc_id
}

data "aws_subnet" "network" {
  for_each = data.aws_subnet_ids.network.ids
  id       = each.value
}