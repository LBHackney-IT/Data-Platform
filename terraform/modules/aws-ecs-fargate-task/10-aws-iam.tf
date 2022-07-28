resource "aws_iam_role" "fargate" {
  tags = var.tags

  name               = "${var.operation_name}-fargate"
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

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "s3.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "task_role" {
  tags = var.tags

  name               = "${var.operation_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy" "task_role" {
  name   = "${var.operation_name}-task-role-policy"
  role   = aws_iam_role.task_role.id
  policy = var.ecs_task_role_policy_document
}

resource "aws_iam_role" "cloudwatch_run_ecs_events" {
  tags = var.tags

  name               = "${var.operation_name}-run-ecs-task"
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
  name   = "${var.operation_name}-ecs-events-run-task"
  role   = aws_iam_role.cloudwatch_run_ecs_events.id
  policy = data.aws_iam_policy_document.event_run_policy.json
}

data "aws_iam_policy_document" "event_run_policy" {
  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.task_role.arn,
      aws_iam_role.fargate.arn
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
    resources = [for task_def in aws_ecs_task_definition.task_definition : replace(task_def.arn, "/:\\d+$/", ":*")]

    condition {
      test     = "StringLike"
      variable = "ecs:cluster"
      values   = [var.ecs_cluster_arn]
    }
  }
}
