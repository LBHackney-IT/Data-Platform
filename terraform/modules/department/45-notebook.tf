locals {
  create_notebook = var.notebook_instance != null && var.is_live_environment
}

module "sagemaker" {
  count                         = local.create_notebook ? 1 : 0
  source                        = "../sagemaker"
  development_endpoint_role_arn = module.department_iam.glue_agent_role_arn
  tags                          = var.tags
  identifier_prefix             = var.short_identifier_prefix
  python_libs                   = try(var.notebook_instance.extra_python_libs, null)
  extra_jars                    = try(var.notebook_instance.extra_jars, null)
  instance_name                 = local.department_identifier
  github_repository             = try(var.notebook_instance.github_repository, null)
}