resource "aws_ecr_repository" "worker" {
    name  = "${var.instance_name}"
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name  = "${var.instance_name}"
}

data "template_file" "task_definition_template" {
  template = file("${path.module}/task_definition_template.json")
  vars = {
    REPOSITORY_URL = aws_ecr_repository.worker.repository_url
    LOG_GROUP = aws_cloudwatch_log_group.ecs_task_logs.name
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "${var.instance_name}"
  container_definitions = data.template_file.task_definition_template.rendered
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.fargate.arn
}

resource "aws_iam_role" "fargate" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-fargate")
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fargate_ecs_task_execution_attachment" {
  role = aws_iam_role.fargate.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "fargate_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  tags = var.tags

  name = "${var.instance_name}-ecs-task-logs"
}
