locals {
  operation_name = "${local.short_identifier_prefix}backfill-production-to-pre-production"
}

resource "aws_ecr_repository" "worker" {
  tags = module.tags.values
  name = local.operation_name
}

resource "aws_ecs_cluster" "ecs_cluster" {
  tags = module.tags.values
  name = local.operation_name
}

data "template_file" "task_definition_template" {
  template = <<TEMPLATE
  [{
    "essential": true,
    "memory": 512,
    "name": "$${OPERATION_NAME}",
    "cpu": 2,
    "image": "$${REPOSITORY_URL}:latest",
    "environment": [
      { "name": "NUMBER_OF_DAYS_TO_RETAIN", "value": "$${NUMBER_OF_DAYS_TO_RETAIN}" },
      { "name": "S3_SYNC_TARGET", "value": "$${S3_SYNC_TARGET}" },
      { "name": "S3_SYNC_SOURCE", "value": "$${S3_SYNC_SOURCE}" }
    ],
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
    OPERATION_NAME           = local.operation_name
    REPOSITORY_URL           = aws_ecr_repository.worker.repository_url
    LOG_GROUP                = aws_cloudwatch_log_group.ecs_task_logs.name
    NUMBER_OF_DAYS_TO_RETAIN = 7
    S3_SYNC_SOURCE           = module.raw_zone.bucket_id
    S3_SYNC_TARGET           = "dataplatform-stg-raw-zone-prod-copy"
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  tags = module.tags.values

  family                   = local.operation_name
  container_definitions    = data.template_file.task_definition_template.rendered
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_iam_role" "fargate" {
  tags = module.tags.values

  name               = "${local.operation_name}fargate"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fargate_ecs_task_execution_attachment" {
  role       = aws_iam_role.fargate.name
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

resource "aws_iam_role" "task_role" {
  tags = module.tags.values

  name               = "${local.operation_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy" "task_role" {
  name   = "${local.operation_name}-task-role-policy"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_role.json
}

data "aws_iam_policy_document" "task_role" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone-prod-copy*"
    ]
  }
}

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  tags = module.tags.values

  name = "${local.operation_name}-ecs-task-logs"
}
