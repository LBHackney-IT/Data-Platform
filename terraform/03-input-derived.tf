# Any internal local variables should be declared here. We also import the tag module for convenience
module "tags" {
  source = "../infrastructure/modules/tags"

  application          = var.application
  automation_build_url = var.automation_build_url
  confidentiality      = var.confidentiality
  custom_tags          = var.custom_tags
  department           = var.department
  environment          = var.environment
  phase                = var.phase
  project              = var.project
  stack                = var.stack
  team                 = var.team
}

locals {
  is_live_environment           = terraform.workspace == "default" ? true : false
  team_snake                    = lower(replace(var.team, " ", "-"))
  environment                   = lower(replace(local.is_live_environment ? var.environment : terraform.workspace, " ", "-"))
  application_snake             = lower(replace(var.application, " ", "-"))
  identifier_prefix             = lower("${local.application_snake}-${local.environment}")
  short_identifier_prefix       = lower(replace(local.is_live_environment ? "" : "${terraform.workspace}-", " ", "-"))
  glue_temp_storage_bucket_path = "s3://${module.glue_temp_storage.bucket_id}/"
}

data "aws_caller_identity" "data_platform" {}

data "aws_caller_identity" "api_account" {
  provider = aws.aws_api_account
}
