# Any internal local variables should be declared here. We also import the tag module for convenience
module "tags" {
  source = "../infrastructure/modules/tags"

  application          = var.application
  automation_build_url = var.automation_build_url
  confidentiality      = var.confidentiality
  custom_tags          = merge(var.custom_tags, { TerraformWorkspace = terraform.workspace })
  department           = var.department
  environment          = var.environment
  phase                = var.phase
  project              = var.project
  stack                = var.stack
  team                 = var.team
}

locals {
  is_live_environment             = terraform.workspace == "default" ? true : false
  team_snake                      = lower(replace(var.team, " ", "-"))
  environment                     = lower(replace(local.is_live_environment ? var.environment : terraform.workspace, " ", "-"))
  application_snake               = lower(replace(var.application, " ", "-"))
  identifier_prefix               = lower("${local.application_snake}-${local.environment}")
  short_identifier_prefix         = lower(replace(local.is_live_environment ? "" : "${terraform.workspace}-", " ", "-"))
  google_group_admin_display_name = local.is_live_environment ? "saml-aws-data-platform-super-admins@hackney.gov.uk" : var.email_to_notify
  housing_repairs_department_identifier = replace(lower(module.department_housing_repairs.name), "/[^a-zA-Z0-9]+/", "-")
  parking_department_identifier = replace(lower(module.department_parking.name), "/[^a-zA-Z0-9]+/", "-")
  data_and_insights_department_identifier = replace(lower(module.department_data_and_insight.name), "/[^a-zA-Z0-9]+/", "-")
  env_enforcement_department_identifier = replace(lower(module.department_env_enforcement.name), "/[^a-zA-Z0-9]+/", "-")
  tags_with_housing_repairs_department = merge(module.tags.values, { "PlatformDepartment" = local.housing_repairs_department_identifier })
  tags_with_parking_department             = merge(module.tags.values, { "PlatformDepartment" = local.parking_department_identifier })
  tags_with_data_and_insights_department   = merge(module.tags.values, { "PlatformDepartment" = local.data_and_insights_department_identifier })
  tags_with_env_enforcement_department = merge(module.tags.values, { "PlatformDepartment" = local.env_enforcement_department_identifier })
}

data "aws_caller_identity" "data_platform" {}

data "aws_caller_identity" "api_account" {
  provider = aws.aws_api_account
}
