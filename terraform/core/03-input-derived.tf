# Any internal local variables should be declared here. We also import the tag module for convenience
module "tags" {
  source = "git@github.com:LBHackney-IT/aws-tags-lbh.git?ref=v1.1.1"

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
  is_live_environment                      = terraform.workspace == "default" ? true : false
  is_development_environment               = terraform.workspace == "default" ? false : true
  is_production_environment                = var.environment == "prod"
  is_production_or_development_environment = local.is_production_environment || local.is_development_environment
  team_snake                               = lower(replace(var.team, " ", "-"))
  environment                              = lower(replace(local.is_live_environment ? var.environment : terraform.workspace, " ", "-"))
  application_snake                        = lower(replace(var.application, " ", "-"))
  identifier_prefix                        = lower("${local.application_snake}-${local.environment}")
  short_identifier_prefix                  = lower(replace(local.is_live_environment ? "" : "${terraform.workspace}-", " ", "-"))
  google_group_admin_display_name          = local.is_live_environment ? "saml-aws-data-platform-super-admins@hackney.gov.uk" : var.email_to_notify
}

data "aws_caller_identity" "data_platform" {}

data "aws_caller_identity" "api_account" {
  provider = aws.aws_api_account
}

locals {
  glue_crawler_excluded_blobs = [
    "*.json",
    "*.txt",
    "*.zip",
    "*.xlsx"
  ]
}

data "aws_ssm_parameter" "aws_vpc_id" {
  name = "/${local.application_snake}-${local.is_live_environment ? var.environment : "dev"}/vpc/vpc_id"
}

// ==== LANDING ZONE ===========
resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${local.identifier_prefix}-landing-zone-database"

  lifecycle {
    prevent_destroy = true
  }
}
