output "ecr_repository_worker_endpoint" {
  value = aws_ecr_repository.worker.repository_url
}

output "task_role" {
  value = aws_iam_role.task_role.arn
}

output "event_rule_names" {
  value = [for event_rule in aws_cloudwatch_event_rule.ecs_task : event_rule.name]
}

output "event_rule_arns" {
  value = [for event_rule in aws_cloudwatch_event_rule.ecs_task : event_rule.arn]
}