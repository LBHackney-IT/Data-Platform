//module "kafka_event_streaming" {
//  source      = "../modules/kafka-event-streaming"
//  tags        = module.tags.values
//  environment = var.environment
//  project     = var.project
//
//  identifier_prefix              = local.identifier_prefix
//  short_identifier_prefix        = local.short_identifier_prefix
//  vpc_id                         = data.aws_vpc.network.id
//  subnet_ids                     = data.aws_subnet_ids.network.ids
//  s3_bucket_to_write_to          = module.raw_zone
//  role_arns_to_share_access_with = ""
//  cross_account_lambda_roles = [
//    "arn:aws:iam::937934410339:role/mtfh-reporting-data-listener/development/mtfh-reporting-data-listener-lambdaExecutionRole",
//    "arn:aws:iam::364864573329:role/mtfh-reporting-data-listener/development/mtfh-reporting-data-listener-lambdaExecutionRole"
//  ]
//}