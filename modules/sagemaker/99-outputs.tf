output "notebook_arn" {
  value = aws_sagemaker_notebook_instance.nb.arn
}

output "notebook_name" {
  value = aws_sagemaker_notebook_instance.nb.name
}

output "notebook_role_arn" {
  value = aws_iam_role.notebook.arn
}

output "lifecycle_configuration_arn" {
  value = aws_sagemaker_notebook_instance_lifecycle_configuration.sagemaker_lifecycle.arn
}
