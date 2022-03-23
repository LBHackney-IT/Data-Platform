resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id = "${var.operation_name}-schedule"
  arn       = aws_ecs_cluster.ecs_cluster.arn
  rule      = aws_cloudwatch_event_rule.task_schedule.name
  role_arn  = aws_iam_role.cloudwatch_run_ecs_events.arn

  ecs_target {
    tags                = var.tags
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.task_definition.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.aws_subnet_ids
    }
  }
}

resource "aws_cloudwatch_event_rule" "task_schedule" {
  tags = var.tags

  name                = "${var.operation_name}-scheduled-event"
  description         = "Runs Fargate task ${var.operation_name}: ${var.task_schedule}"
  schedule_expression = var.task_schedule
}
