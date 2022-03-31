resource "aws_ecs_service" "datahub-service" {
  name            = "${var.operation_name}"
  cluster         = aws_ecs_cluster.datahub.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.aws_subnet_ids
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.container_properties.load_balancer_required == true ? [1] : []
    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = var.container_properties.container_name
      container_port   = var.container_properties.port
    }
  }

  tags = var.tags
}
