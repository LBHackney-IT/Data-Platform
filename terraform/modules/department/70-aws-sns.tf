resource "aws_sns_topic" "glue_jobs" {
  tags = merge(var.tags, { "PlatformDepartment" = local.department_identifier })

  name = "glue-failure-notification-${var.short_identifier_prefix}${local.department_identifier}"
}

locals {
  email_to_notify = var.google_group_display_name == null ? var.google_group_admin_display_name : var.google_group_display_name
}

resource "aws_sns_topic_subscription" "glue_failure_notifications" {
  endpoint  = local.email_to_notify
  protocol  = "email"
  topic_arn = aws_sns_topic.glue_jobs.arn
}
