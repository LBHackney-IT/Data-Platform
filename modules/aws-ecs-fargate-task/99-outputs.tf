output "ecr_repository_worker_endpoint" {
  value = aws_ecr_repository.worker.repository_url
}

output "task_role" {
  value = aws_iam_role.task_role.arn
}

output "event_rule_name" {
  value = aws_cloudwatch_event_rule.ecs_task.name
}

output "event_rule_arn" {
  value = aws_cloudwatch_event_rule.ecs_task.arn
}