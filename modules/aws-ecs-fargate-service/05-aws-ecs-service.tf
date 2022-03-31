resource "aws_ecs_service" "datahub_frontend_react_service" {
  name            = "${var.operation_name}${var.container_properties.container_name}"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  tags            = var.tags

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.aws_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.container_properties.container_name
    container_port   = var.container_properties.port
  }
}
