resource "random_id" "random_subnet" {
  byte_length = 2
}

locals {
  subnet_ids_random_index = random_id.random_subnet.dec % length(var.vpc_subnet_ids)
  instance_subnet_id      = var.vpc_subnet_ids[local.subnet_ids_random_index]
}