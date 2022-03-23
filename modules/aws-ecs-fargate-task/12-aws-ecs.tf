data "template_file" "task_definition_template" {
  template = <<TEMPLATE
  [{
    "essential": true,
    "memory": 512,
    "name": "$${OPERATION_NAME}",
    "cpu": 256,
    "image": "$${REPOSITORY_URL}:latest",
    "environment": $${ENVIRONMENT_VARIABLES},
    "LogConfiguration": {
      "LogDriver": "awslogs",
      "Options": {
        "awslogs-group": "$${LOG_GROUP}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "$${OPERATION_NAME}"
      }
    }
  }]
  TEMPLATE

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
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate.arn
  task_role_arn            = aws_iam_role.task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  tags = var.tags

  name = "${var.operation_name}-ecs-task-logs"
}
