resource "aws_ecs_task_definition" "task_definition" {
  tags = var.tags

  family                   = "${var.operation_name}${var.container_properties.container_name}"
  container_definitions    = data.template_file.task_definition_template.rendered
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_properties.cpu
  memory                   = var.container_properties.memory
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task_role.arn

  dynamic "volume" {
    for_each = var.container_properties.volumes
    content {
      name = volume.value
    }
  }
}

data "template_file" "task_definition_template" {
  template = jsonencode([
    {
      name : var.container_properties.container_name,
      image : var.container_properties.image_name,
      essential : true,
      memory : var.container_properties.memory,
      cpu : var.container_properties.cpu,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : var.cloudwatch_log_group_name,
          awslogs-region : "eu-west-2",
          awslogs-stream-prefix : "${var.operation_name}${var.container_properties.container_name}"
        }
      },
      portMappings : [
        {
          containerPort : var.container_properties.port,
          hostPort : var.container_properties.port,
          protocol : "tcp"
        }
      ],
      environment : var.container_properties.environment_variables
      mountPoints : var.container_properties.mount_points
    }
  ])
}
