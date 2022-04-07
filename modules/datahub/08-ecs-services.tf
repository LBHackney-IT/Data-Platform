module "datahub_actions" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = null
  alb_target_group_arn      = null
  alb_security_group_id     = null
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
  alb_id                    = aws_alb.datahub_frontend_react.id
  alb_target_group_arn      = aws_alb_target_group.datahub_frontend_react.arn
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
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub_gms.id
  alb_target_group_arn      = aws_alb_target_group.datahub_gms.arn
  alb_security_group_id     = aws_security_group.datahub_gms.id
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_gms
}

module "mysql_setup" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = null
  alb_target_group_arn      = null
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
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = null
  alb_target_group_arn      = null
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
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = null
  alb_target_group_arn      = null
  alb_security_group_id     = null
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.kafka_setup
}

module "neo4j" {
  source = "../aws-ecs-docker-service"

  tags                      = var.tags
  operation_name            = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  environment               = var.environment
  identifier_prefix         = var.identifier_prefix
  short_identifier_prefix   = var.short_identifier_prefix
  alb_id                    = aws_alb.datahub_neo4j.id
  alb_target_group_arn      = aws_alb_target_group.datahub_neo4j.arn
  alb_security_group_id     = aws_security_group.datahub_neo4j.id
  vpc_id                    = var.vpc_id
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.neo4j
}
