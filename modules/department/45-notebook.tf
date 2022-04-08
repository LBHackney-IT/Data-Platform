module "sagemaker" {
  count                         = var.notebook_instance == null ? 0 : 1
  source                        = "../sagemaker"
  development_endpoint_role_arn = aws_iam_role.glue_agent.arn
  tags                          = var.tags
  identifier_prefix             = var.short_identifier_prefix
  python_libs                   = var.notebook_instance.extra_python_libs
  extra_jars                    = var.notebook_instance.extra_jars
  instance_name                 = local.department_identifier
  github_repository             = var.notebook_instance.github_repository
}