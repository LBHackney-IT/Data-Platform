output "ecr_repository_worker_endpoint" {
  value = aws_ecr_repository.worker.repository_url
}

output "task_role" {
  value = aws_iam_role.task_role.arn
}