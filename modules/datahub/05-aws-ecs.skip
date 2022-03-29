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
    target_group_arn = var.alb_target_group_arn
    container_name   = "datahub"
    container_port   = 4000
  }

  tags = var.tags
}

data "template_file" "task_definition_template" {
  template = file("./deployment-files/task-definition.tpl")
  vars = {
    OPERATION_NAME        = var.operation_name
    REPOSITORY_URL        = aws_ecr_repository.worker.repository_url
    LOG_GROUP             = aws_cloudwatch_log_group.datahub.name
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

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.short_identifier_prefix}datahub-ecs"
  description = "Allow inbound access to the ECS service from the ALB only"

  ingress {
    protocol        = "tcp"
    from_port       = 4000
    to_port         = 4000
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [var.alb_id.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
