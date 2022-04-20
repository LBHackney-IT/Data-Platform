module "datahub_frontend_react" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = aws_alb.datahub_frontend_react.id
  alb_target_group_arns     = [{ arn = aws_alb_target_group.datahub_frontend_react.arn, port = aws_alb_target_group.datahub_frontend_react.port }]
  alb_security_group_id     = aws_security_group.datahub_frontend_react.id
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_frontend_react
}

module "datahub_gms" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = aws_alb.datahub_gms.id
  alb_target_group_arns     = [{ arn = aws_alb_target_group.datahub_gms.arn, port = aws_alb_target_group.datahub_gms.port }]
  alb_security_group_id     = aws_security_group.datahub_gms.id
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_gms
}

module "datahub_mae_consumer" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = null
  alb_target_group_arns     = []
  alb_security_group_id     = null
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_mae_consumer
}

module "datahub_mce_consumer" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = null
  alb_target_group_arns     = []
  alb_security_group_id     = null
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_mce_consumer
}

module "mysql_setup" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = null
  alb_target_group_arns     = []
  alb_security_group_id     = null
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.mysql_setup
}

module "elasticsearch_setup" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = null
  alb_target_group_arns     = []
  alb_security_group_id     = null
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.elasticsearch_setup
}

module "kafka_setup" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = null
  alb_target_group_arns     = []
  alb_security_group_id     = null
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.kafka_setup
}

module "datahub_actions" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  alb_id                    = null
  alb_target_group_arns     = []
  alb_security_group_id     = null
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_actions
}
