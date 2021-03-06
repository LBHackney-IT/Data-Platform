data "aws_caller_identity" "current" {}

data "aws_instance" "qlik-sense-aws-instance" {
  filter {
    name   = "tag:Name"
    values = ["Qlik Migration ${upper(var.environment)}"]
  }
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}