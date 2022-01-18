module "kafka_event_streaming" {
  source      = "../modules/kafka-event-streaming"
  tags        = module.tags.values
  environment = var.environment
  project     = var.project

  identifier_prefix              = local.short_identifier_prefix
  vpc_id                         = data.aws_vpc.network.id
  subnet_ids                     = data.aws_subnet_ids.network.ids
  role_arns_to_share_access_with = ""
  cross_account_lambda_roles     = [""]
}