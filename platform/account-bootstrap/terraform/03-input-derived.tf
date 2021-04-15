# Any internal local variables should be declared here. We also import the tag module for convenience
module "tags" {
  source = "../../../modules/tags"

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

  # Just an example of using a local variable
  s3_bucket_name = lower("${var.team}-${var.project}-${var.environment}-new")
}
