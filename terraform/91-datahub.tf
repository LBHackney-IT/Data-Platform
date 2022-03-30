module "datahub" {
  source                  = "../modules/datahub"
  tags                    = module.tags.values
  operation_name          = local.short_identifier_prefix
  environment             = var.environment
  identifier_prefix       = local.identifier_prefix
  short_identifier_prefix = local.short_identifier_prefix
  aws_subnet_ids          = local.subnet_ids_list
  vpc_id                  = var.aws_dp_vpc_id
}