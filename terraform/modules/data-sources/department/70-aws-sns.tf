data "aws_sns_topic" "glue_jobs" {
  name = "glue-failure-notification-${var.short_identifier_prefix}${local.department_identifier}"
}
