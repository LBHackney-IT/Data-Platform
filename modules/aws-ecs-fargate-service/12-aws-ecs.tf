resource "aws_ecs_service" "datahub-service" {
  name            = "${var.operation_name}-ecs-service"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.vpc_subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.datahub.arn
    container_name   = "datahub"
    container_port   = 4000
  }

  depends_on = [aws_alb_listener.datahub_https, aws_iam_role_policy_attachment.ecs_task_execution_role]

  tags = var.tags
}

data "template_file" "task_definition_template" {
  template = file("./templates-files/task-definition.tpl")
  vars = {
    OPERATION_NAME        = var.operation_name
    REPOSITORY_URL        = aws_ecr_repository.worker.repository_url
    LOG_GROUP             = aws_cloudwatch_log_group.ecs_task_logs.name
    ENVIRONMENT_VARIABLES = jsonencode(var.environment_variables)
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  tags = var.tags

  family                   = var.operation_name
  container_definitions    = data.template_file.task_definition_template.rendered
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 4000
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  tags = var.tags

  name = "${var.operation_name}-ecs-task-logs"
}
