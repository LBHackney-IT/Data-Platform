module "datahub" {
  source = "../aws-ecs-fargate-service"

  tags                    = var.tags
  operation_name          = var.short_identifier_prefix
  environment_variables   = var.environment_variables
  ecs_cluster_arn         = aws_ecs_cluster.datahub.arn
  environment             = var.environment
  identifier_prefix       = var.identifier_prefix
  short_identifier_prefix = var.short_identifier_prefix
  alb_id                  = aws_alb.datahub.id
  alb_target_group_arn    = aws_alb_target_group.datahub.arn
  alb_security_group_id   = aws_security_group.datahub_alb.id
  aws_subnet_ids          = var.aws_subnet_ids
  vpc_id                  = var.vpc_id
  ecr_repository_url      = aws_ecr_repository.datahub.repository_url
  container_properties    = local.datahub_frontend_react_properties
}
