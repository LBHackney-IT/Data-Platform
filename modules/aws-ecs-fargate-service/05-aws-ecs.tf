resource "aws_ecs_service" "datahub-service" {
  name            = "${var.operation_name}-${var.container_properties.container_name}"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.aws_subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.operation_name
    container_port   = var.container_properties.port
  }

  tags = var.tags
}

data "template_file" "task_definition_template" {
  template = file("${path.module}/deployment-files/task-definition.tpl")
  vars = {
    OPERATION_NAME = "${var.operation_name}-${var.container_properties.container_name}"
    REPOSITORY_URL = var.ecr_repository_url
    LOG_GROUP      = aws_cloudwatch_log_group.datahub.name
    PORT           = var.container_properties.port
    MEMORY         = var.container_properties.memory
    CPU            = var.container_properties.cpu
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  tags = var.tags

  family                   = "${var.operation_name}-${var.container_properties.container_name}"
  container_definitions    = data.template_file.task_definition_template.rendered
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_properties.cpu
  memory                   = var.container_properties.memory
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.short_identifier_prefix}datahub-ecs"
  description = "Allow inbound access to the ECS service from the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_properties.port
    to_port         = var.container_properties.port
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [var.alb_security_group_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
