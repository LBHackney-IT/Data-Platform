module "datahub" {
  source                               = "../modules/datahub"
  tags                                 = module.tags.values
  vpc_id                               = data.aws_vpc.network.id
  vpc_subnet_ids                       = local.subnet_ids_list
  instance_type                        = var.datahub_instance_type
  ssl_certificate_domain               = var.datahub_ssl_certificate_domain
  identifier_prefix                    = local.identifier_prefix
  short_identifier_prefix              = local.short_identifier_prefix
  environment                          = var.environment
  aws_ami_id                           = data.aws_ami.latest_amazon_linux_2.id
  amazon_ssm_managed_instance_core_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
}