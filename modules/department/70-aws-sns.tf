
// Can you turn on collaborative inbox using google provider?

resource "aws_sns_topic" "glue_jobs" {
  tags = var.tags

  name = "${var.short_identifier_prefix}failed-glue-job-notifications"
}


resource "aws_sns_topic_subscription" "glue_error_notifications" {
  topic_arn = aws_sns_topic.glue_jobs.arn
  protocol  = "email"
  endpoint  = "ben.dalton@madetech.com" // var.google_group_display_name
}

// What if there are jobs not linked to a department, should we have an admin SNS topic that gets attached to all jobs?
// Or enforce that every job has a department?