
resource "aws_iam_role" "cloudwatch_run_ecs_events" {
  name               = "${var.instance_name}-run-ecs-task"
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

resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name   = "${var.instance_name}-ecs-events-run-task-with-any-role"
  role   = aws_iam_role.cloudwatch_run_ecs_events.id
  policy = data.aws_iam_policy_document.event_run_policy.json
}

data "aws_iam_policy_document" "event_run_policy" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"] // TODO: When we use this "PassRole", restrict this "resources" to just that.
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = [replace(aws_ecs_task_definition.task_definition.arn, "/:\\d+$/", ":*")]
  }
}

resource "aws_cloudwatch_event_target" "run_ingestor_task" {
  target_id = var.instance_name
  arn       = aws_ecs_cluster.ecs_cluster.arn
  rule      = aws_cloudwatch_event_rule.new_s3_object.name
  role_arn  = aws_iam_role.cloudwatch_run_ecs_events.arn

  ecs_target {
    task_count          = 1
    launch_type         = "FARGATE"
    task_definition_arn = aws_ecs_task_definition.task_definition.arn

    network_configuration {
      subnets          = var.aws_subnet_ids
      assign_public_ip = true
    }
  }
}

resource "aws_cloudwatch_event_rule" "new_s3_object" {
  name        = "${var.instance_name}-new-s3-object"
  description = "Fires when a new S3 Object is placed in the SQL bucket"
  event_pattern = jsonencode({
    "source" : [
      "aws.s3"
    ],
    "detail-type" : [
      "AWS API Call via CloudTrail"
    ],
    "detail" : {
      "eventSource" : [
        "s3.amazonaws.com"
      ],
      "eventName" : [
        "PutObject",
        "CompleteMultipartUpload"
      ],
      "requestParameters" : {
        "bucketName" : [
          var.watched_bucket_name
        ]
      }
    }
  })
}
