data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# data "aws_msk_cluster" "kafka_cluster" {
#   cluster_name = "${var.short_identifier_prefix}event-streaming"
# }