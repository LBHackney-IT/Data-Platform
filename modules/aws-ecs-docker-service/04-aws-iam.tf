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
  tags               = var.tags
  name               = "${var.short_identifier_prefix}${var.container_properties.container_name}"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy_attachment" "datahub_role_policy_ssm" {
  name       = "${var.short_identifier_prefix}${var.container_properties.container_name}role-policy-ssm"
  policy_arn = aws_iam_policy.datahub_role_policy_ssm.arn
  roles      = [aws_iam_role.task_role.name]
}

resource "aws_iam_policy" "datahub_role_policy_ssm" {
  name   = "${var.short_identifier_prefix}${var.container_properties.container_name}policy-ssm"
  policy = data.aws_iam_policy_document.datahub_can_access_ssm.json
}

data "aws_iam_policy_document" "datahub_can_access_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"
    ]
  }
}

resource "aws_iam_role" "cloudwatch_run_ecs_events" {
  tags = var.tags

  name               = "${var.short_identifier_prefix}${var.container_properties.container_name}run-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_role.json
}

data "aws_iam_policy_document" "cloudwatch_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "events.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role_policy" "ecs_events_run_task" {
  name   = "${var.short_identifier_prefix}ecs-events-run-task"
  role   = aws_iam_role.cloudwatch_run_ecs_events.id
  policy = data.aws_iam_policy_document.event_run_policy.json
}

data "aws_iam_policy_document" "event_run_policy" {
  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.task_role.arn
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = [aws_ecs_task_definition.task_definition.arn]

    condition {
      test     = "StringLike"
      variable = "ecs:cluster"
      values   = [var.ecs_cluster_arn]
    }
  }
}