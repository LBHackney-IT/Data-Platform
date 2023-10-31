resource "aws_lambda_permission" "allow_cloudwatch_snapshot_export_trigger" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  action        = "lambda:InvokeFunction"
  function_name = module.trigger_rds_snapshot_export.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_snapshot_created_event_rule[each.key].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_snapshot_copier" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  action        = "lambda:InvokeFunction"
  function_name = module.rds_snapshot_s3_to_s3_copier.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_snapshot_exported_event_rule[each.key].arn
}

resource "aws_iam_role" "cloudwatch_events_role" {
  name = "cloudwatch-events-invocation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_events_policy" {
  name = "cloudwatch-events-invocation-policy"
  role = aws_iam_role.cloudwatch_events_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          module.trigger_rds_snapshot_export.lambda_function_arn,
          module.rds_snapshot_s3_to_s3_copier.lambda_function_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "rds_snapshot_to_s3_lambda_role" {
  name               = "rds-snapshot-to-s3-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

}

data "aws_iam_policy_document" "rds_snapshot_to_s3_lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    actions   = ["iam:PassRole"]
    effect    = "Allow"
    resources = [aws_iam_role.rds_snapshot_export_service.arn]
  }

  statement {
    actions = [
      "rds:StartExportTask",
      "rds:DescribeExportTasks"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    sid = "AllowKMSDecrypt"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    effect = "Allow"
    resources = [
      var.rds_export_storage_kms_key_arn
    ]
  }
}



resource "aws_iam_role" "rds_snapshot_s3_to_s3_copier_lambda_role" {
  name               = "rds-snapshot-s3-to-s3-copier-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "rds_snapshot_s3_to_s3_copier_role_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    effect = "Allow"
    resources = [
      var.rds_export_bucket_arn,
      "${var.rds_export_bucket_arn}/*",
      var.target_bucket_arn,
      "${var.target_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey"
    ]
    effect = "Allow"
    resources = [
      var.rds_export_storage_kms_key_arn,
      var.target_bucket_kms_key_arn
    ]
  }

  statement {
    actions = [
      "glue:StartWorkflowRun"
    ]
    effect = "Allow"
    resources = [
      var.workflow_arn,
      var.backdated_workflow_arn
    ]
  }
}

resource "aws_iam_policy" "rds_snapshot_s3_to_s3_copier_role_policy" {
  name   = lower("${var.identifier_prefix}-rds-snapshot-s3-to-s3-copier-lambda-policy")
  policy = data.aws_iam_policy_document.rds_snapshot_s3_to_s3_copier_role_policy.json
  tags   = var.tags
}

resource "aws_iam_policy_attachment" "rds_snapshot_copier_attachment" {
  name       = "${var.identifier_prefix}-rds-snapshot-s3-to-s3-lambda-policy-attachment"
  policy_arn = aws_iam_policy.rds_snapshot_s3_to_s3_copier_role_policy.arn
  roles = [
    aws_iam_role.rds_snapshot_to_s3_lambda_role.name
  ]
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}
