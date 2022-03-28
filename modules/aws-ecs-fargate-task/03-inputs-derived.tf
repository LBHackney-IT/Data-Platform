locals {
  default_task_details = defaults(var.tasks, {
    task_prefix                         = ""
    cloudwatch_rule_schedule_expression = null
    cloudwatch_rule_event_pattern       = null
  })
}