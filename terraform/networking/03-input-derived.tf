# General
module "tags" {
  source = "git@github.com:LBHackney-IT/infrastructure.git//modules/aws-tags-lbh/module?ref=master"

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
  environment       = lower(replace(var.environment, " ", "-"))
  application_snake = lower(replace(var.application, " ", "-"))
  identifier_prefix = lower("${local.application_snake}-${local.environment}")
}
