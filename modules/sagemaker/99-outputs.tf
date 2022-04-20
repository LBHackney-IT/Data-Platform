output "notebook_arn" {
  value = aws_sagemaker_notebook_instance.nb.arn
}

output "notebook_role_arn" {
  value = aws_iam_role.notebook.arn
}