# Any internal local variables should be declared here. We also import the tag module for convenience
module "tags" {
  source = "https://github.com/LBHackney-IT/aws-tags-lbh.git?ref=v1.0.0"

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
