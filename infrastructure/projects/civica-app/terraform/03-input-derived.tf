# General
data "aws_caller_identity" "current" {
  provider = aws.core
}

# locals {
#   # common_tags = {
#   #   "Automation"         = "Cloud Deployment Infrastructure"
#   #   "CostCentre"         = "-"
#   #   "Criticality"        = local.criticality[var.environment]
#   #   "DataClassification" = "-"
#   #   "Environment"        = local.env_display_names[var.environment]
#   #   "ManagedBy"          = "Cloud Deployment Team"
#   #   "ServiceName"        = var.service_name
#   #   "SolutionOwner"      = "-"
#   }

#   criticality = {
#     dev  = "Low"
#     prod = "High"
#     stg  = "High"
#     test = "Medium"
#   }

#   env_display_names = {
#     dev  = "Development"
#     prod = "Production"
#     stg  = "Staging"
#     test = "Test"
#   }
# }

module "tags" {
  source = "../modules/tags"

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
