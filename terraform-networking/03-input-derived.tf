# General
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
