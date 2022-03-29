module "datahub" {
  source = "../modules/aws-ecs-fargate-service"

  tags                          = module.tags.values
  operation_name                = "${local.short_identifier_prefix}datahub"
  environment_variables         = local.environment_variables
  ecs_task_role_policy_document = data.aws_iam_policy_document.task_role.json
  aws_subnet_ids                = data.aws_subnet_ids.network.ids
  ecs_cluster_arn               = aws_ecs_cluster.workers.arn
  environment                   = var.environment
  identifier_prefix             = local.identifier_prefix
  short_identifier_prefix       = local.short_identifier_prefix
  ssl_certificate_domain        = var.datahub_ssl_certificate_domain
  vpc_id                        = var.aws_dp_vpc_id
  vpc_subnet_ids                = local.subnet_ids_list
}