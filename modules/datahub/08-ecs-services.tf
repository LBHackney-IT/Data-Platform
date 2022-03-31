module "broker" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.broker
}

module "datahub_actions" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_actions
}

module "datahub_frontend_react" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_frontend_react
}

module "datahub_gms" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_gms
}

module "zookeeper" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.zookeeper
}

module "mysql_setup" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.mysql_setup
}

module "elasticsearch_setup" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.elasticsearch_setup
}

module "kafka_setup" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.kafka_setup
}

module "schema_registry" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub.id
  alb_target_group_arn      = aws_alb_target_group.datahub.arn
  alb_security_group_id     = aws_security_group.datahub_alb.id
  aws_subnet_ids            = data.aws_subnet_ids.subnet_ids.ids
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.schema_registry
}
