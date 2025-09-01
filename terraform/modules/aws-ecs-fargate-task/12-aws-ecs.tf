data "template_file" "task_definition_template" {
  for_each = { for task in local.tasks : task.task_id => task }
  template = <<TEMPLATE
  [{
    "essential": true,
    "memory": $${MEMORY},
    "name": "$${OPERATION_NAME}",
    "cpu": $${CPU},
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
    ENVIRONMENT_VARIABLES = jsonencode(each.value.environment_variables)
    CPU                   = each.value.task_cpu
    MEMORY                = each.value.task_memory
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  tags     = var.tags
  for_each = { for task in local.tasks : task.task_id => task }

  family                   = "${each.value.task_id}${var.operation_name}"
  container_definitions    = data.template_file.task_definition_template[each.key].rendered
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.task_cpu
  memory                   = each.value.task_memory
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate.arn
  task_role_arn            = aws_iam_role.task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  ephemeral_storage {
    size_in_gib = 50
  }
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  tags = var.tags

  name = "${var.operation_name}-ecs-task-logs"
}
