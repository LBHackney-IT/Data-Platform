# Any internal local variables should be declared here. We also import the tag module for convenience
module "tags" {
  source = "../infrastructure/modules/audit/tags"

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
  team_snake        = lower(replace(var.team, " ", "-"))
  application_snake = lower(replace(var.application, " ", "-"))
  identifier_prefix = lower("${local.team_snake}-${local.application_snake}-${var.environment}")
}
