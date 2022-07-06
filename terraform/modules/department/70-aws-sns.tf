resource "aws_sns_topic" "glue_jobs" {
  tags = merge(var.tags, { "PlatformDepartment" = local.department_identifier })

  name              = "glue-failure-notification-${var.short_identifier_prefix}${local.department_identifier}"
  kms_master_key_id = aws_kms_key.glue_jobs_kms_key.key_id
}

resource "aws_kms_key" "glue_jobs_kms_key" {
  tags = merge(var.tags, { "PlatformDepartment" = local.department_identifier })

  description             = "${var.environment} - glue-failure-notification-${var.short_identifier_prefix}${local.department_identifier} KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.glue_jobs_kms_key_policy.json
}

data "aws_iam_policy_document" "glue_jobs_kms_key_policy" {

  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    resources = ["*"]
  }
}


locals {
  email_to_notify = var.google_group_display_name == null ? var.google_group_admin_display_name : var.google_group_display_name
}

resource "aws_sns_topic_subscription" "glue_failure_notifications" {
  endpoint  = local.email_to_notify
  protocol  = "email"
  topic_arn = aws_sns_topic.glue_jobs.arn
}
