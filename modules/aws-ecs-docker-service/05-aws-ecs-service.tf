resource "aws_ecs_service" "datahub_service" {
  count           = var.container_properties.standalone_onetime_task ? 0 : 1
  name            = "${var.operation_name}${var.container_properties.container_name}"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  tags            = var.tags

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks[0].id]
    subnets         = data.aws_subnet.subnets.*.id
  }

  dynamic "load_balancer" {
    for_each = var.alb_target_group_arns
    content {
      target_group_arn = load_balancer.value.arn
      container_name   = var.container_properties.container_name
      container_port   = load_balancer.value.port
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_security_group" "ecs_tasks" {
  count                  = var.container_properties.standalone_onetime_task ? 0 : 1
  name                   = "${var.operation_name}${var.container_properties.container_name}"
  description            = "Allow inbound access to the ECS service from the ALB only"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  dynamic "ingress" {
    for_each = var.container_properties.load_balancer_required ? [var.alb_security_group_id] : []
    content {
      protocol        = "tcp"
      from_port       = var.container_properties.port
      to_port         = var.container_properties.port
      security_groups = [var.alb_security_group_id]
    }
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = var.vpc_id
}

data "aws_subnet" "subnets" {
  count = length(data.aws_subnet_ids.subnet_ids.ids)
  id    = tolist(data.aws_subnet_ids.subnet_ids.ids)[count.index]
}
