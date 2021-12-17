module "mmh_streaming" {
  source = "../modules/mmh-streaming"
  tags   = module.tags.values

  identifier_prefix = local.short_identifier_prefix
  vpc_id            = data.aws_vpc.network.id
  subnet_ids        = data.aws_subnet_ids.network.ids
}