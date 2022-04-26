module "datahub_frontend_react" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_frontend_react
  load_balancer_properties = {
    target_group_properties = [{ arn = aws_alb_target_group.datahub_frontend_react.arn, port = aws_alb_target_group.datahub_frontend_react.port }]
    security_group_id       = aws_security_group.datahub_frontend_react.id
  }
  is_live_environment = var.is_live_environment
}

module "datahub_gms" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_gms
  load_balancer_properties = {
    target_group_properties = [{ arn = aws_alb_target_group.datahub_gms.arn, port = aws_alb_target_group.datahub_gms.port }]
    security_group_id       = aws_security_group.datahub_gms.id
  }
  is_live_environment = var.is_live_environment
}

module "datahub_mae_consumer" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_mae_consumer
  load_balancer_properties = {
    target_group_properties = []
    security_group_id       = null
  }
  is_live_environment = var.is_live_environment
}

module "datahub_mce_consumer" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_mce_consumer
  load_balancer_properties = {
    target_group_properties = []
    security_group_id       = null
  }
  is_live_environment = var.is_live_environment
}

module "datahub_actions" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.datahub_actions
  load_balancer_properties = {
    target_group_properties = []
    security_group_id       = null
  }
  is_live_environment = var.is_live_environment
}

module "mysql_setup" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.mysql_setup
  load_balancer_properties = {
    target_group_properties = []
    security_group_id       = null
  }
  is_live_environment = var.is_live_environment
  depends_on = [
    aws_db_instance.datahub
  ]
}

module "elasticsearch_setup" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.elasticsearch_setup
  load_balancer_properties = {
    target_group_properties = []
    security_group_id       = null
  }
  is_live_environment = var.is_live_environment
  depends_on = [
    aws_elasticsearch_domain.es
  ]
}

module "kafka_setup" {
  source                    = "../aws-ecs-docker-service"
  tags                      = var.tags
  short_identifier_prefix   = var.short_identifier_prefix
  ecs_cluster_arn           = aws_ecs_cluster.datahub.arn
  vpc_id                    = var.vpc_id
  vpc_subnet_ids            = var.vpc_subnet_ids
  cloudwatch_log_group_name = aws_cloudwatch_log_group.datahub.name
  container_properties      = local.kafka_setup
  load_balancer_properties = {
    target_group_properties = []
    security_group_id       = null
  }
  is_live_environment = var.is_live_environment
}
