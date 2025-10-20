data "aws_caller_identity" "current" {}

#for pre-prod and prod setups only
data "aws_instance" "qlik-sense-aws-instance" {
  filter {
    name   = "tag:Name"
    values =  var.is_production_environment ? ["Qlik Migration ${upper(var.environment)}"] : ["dataplatform-stg-qlik-sense-restore-8"]
  }
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_instance" "qlik-ec2-data-gateway-prod" {
  filter {
    name   = "tag:Name"
    values = ["qlik-data-gateway-prod"]
  }
}