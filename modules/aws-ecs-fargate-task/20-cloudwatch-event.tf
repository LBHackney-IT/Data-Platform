resource "aws_cloudwatch_event_target" "ecs_task" {
  for_each  = var.tasks
  target_id = "${each.value.task_prefix}${var.operation_name}-schedule"
  arn       = var.ecs_cluster_arn
  rule      = values(aws_cloudwatch_event_rule.ecs_task)[*].name
  role_arn  = aws_iam_role.cloudwatch_run_ecs_events.arn

  ecs_target {
    tags                = var.tags
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.task_definition[each.key].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets = var.aws_subnet_ids
    }
  }
}

resource "aws_cloudwatch_event_rule" "ecs_task" {
  tags     = var.tags
  for_each = var.tasks

  name                = "${each.value.task_prefix}${var.operation_name}-scheduled-event"
  description         = "Runs Fargate task ${each.value.task_prefix}${var.operation_name}"
  schedule_expression = each.value.cloudwatch_rule_schedule_expression == null ? null : each.value.cloudwatch_rule_schedule_expression
  event_pattern       = each.value.cloudwatch_rule_event_pattern == null ? null : each.value.cloudwatch_rule_event_pattern
}
