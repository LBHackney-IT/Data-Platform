resource "aws_cloudwatch_event_target" "cloudwatch_event" {
  count     = var.container_properties.standalone_onetime_task ? 1 : 0
  target_id = "${var.operation_name}${var.container_properties.container_name}-event"
  arn       = var.ecs_cluster_arn
  rule      = aws_cloudwatch_event_rule.ecs_task[0].name
  role_arn  = aws_iam_role.cloudwatch_run_ecs_events.arn

  ecs_target {
    tags                = var.tags
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.task_definition.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = data.aws_subnet.subnets.*.id
    }
  }
}

resource "aws_cloudwatch_event_rule" "ecs_task" {
  count               = var.container_properties.standalone_onetime_task ? 1 : 0
  name                = "${var.operation_name}${var.container_properties.container_name}-event"
  description         = "Runs ${var.operation_name}${var.container_properties.container_name} Task"
  schedule_expression = "cron(${upper(formatdate("m h D M EEE YYYY", timeadd(timestamp(), "1m")))})"
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      schedule_expression
    ]
  }
}