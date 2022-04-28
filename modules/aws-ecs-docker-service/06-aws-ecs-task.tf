resource "aws_ecs_task_definition" "task_definition" {
  tags = var.tags

  family                   = "${var.short_identifier_prefix}${var.container_properties.container_name}"
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

  depends_on = [null_resource.docker_pull_push]
}

data "template_file" "task_definition_template" {
  template = jsonencode([
    {
      name : var.container_properties.container_name,
      image : "${aws_ecr_repository.ecr.repository_url}:${var.container_properties.image_tag}",
      essential : true,
      memory : var.container_properties.memory,
      cpu : var.container_properties.cpu,
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-group : var.cloudwatch_log_group_name,
          awslogs-region : data.aws_region.current.name,
          awslogs-stream-prefix : "${var.short_identifier_prefix}${var.container_properties.container_name}"
        }
      },
      portMappings : var.container_properties.port_mappings
      environment : var.container_properties.environment_variables
      secrets : var.container_properties.secrets
      mountPoints : var.container_properties.mount_points
    }
  ])
}
