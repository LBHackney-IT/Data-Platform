module "datahub_ecs_gms_autoscaling_group" {
  source = "../aws-ecs-autoscaling-group"

  name                     = "${var.short_identifier_prefix}datahub-gms"
  ecs_autoscaling_role_arn = aws_iam_role.datahub_ecs_autoscale.arn
  ecs_cluster_name         = aws_ecs_cluster.datahub.name
  ecs_service_name         = module.datahub_gms.service_name
}

module "datahub_ecs_frontend_autoscaling_group" {
  source = "../aws-ecs-autoscaling-group"

  name                     = "${var.short_identifier_prefix}datahub-frontend"
  ecs_autoscaling_role_arn = aws_iam_role.datahub_ecs_autoscale.arn
  ecs_cluster_name         = aws_ecs_cluster.datahub.name
  ecs_service_name         = module.datahub_frontend_react.service_name
}