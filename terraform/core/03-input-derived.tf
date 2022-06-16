# Any internal local variables should be declared here. We also import the tag module for convenience
module "tags" {
  source = "git@github.com:LBHackney-IT/infrastructure.git//modules/aws-tags-lbh/module?ref=master"

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
  is_production_environment       = var.environment == "prod"
  team_snake                      = lower(replace(var.team, " ", "-"))
  environment                     = lower(replace(local.is_live_environment ? var.environment : terraform.workspace, " ", "-"))
  application_snake               = lower(replace(var.application, " ", "-"))
  identifier_prefix               = lower("${local.application_snake}-${local.environment}")
  short_identifier_prefix         = lower(replace(local.is_live_environment ? "" : "${terraform.workspace}-", " ", "-"))
  google_group_admin_display_name = local.is_live_environment ? "saml-aws-data-platform-super-admins@hackney.gov.uk" : var.email_to_notify
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

data "aws_iam_role" "glue_role" {
  name = "${local.identifier_prefix}-glue-role"
}

data "aws_s3_bucket_object" "helpers" {
  bucket = module.glue_scripts.bucket_id
  key    = "python-modules/data_platform_glue_job_helpers-1.0-py3-none-any.whl"
}

data "aws_s3_bucket_object" "jars" {
  bucket = module.glue_scripts.bucket_id
  key    = "jars/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar"
}

data "aws_s3_bucket_object" "pydeequ" {
  bucket = module.glue_scripts.bucket_id
  key    = "python-modules/pydeequ-1.0.1.zip"
}

data "aws_s3_bucket_object" "ingest_database_tables_via_jdbc_connection" {
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/ingest_database_tables_via_jdbc_connection.py"
}

data "aws_s3_bucket_object" "copy_tables_landing_to_raw" {
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/copy_tables_landing_to_raw.py"
}

data "aws_s3_bucket_object" "dynamodb_tables_ingest" {
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/ingest_tables_from_dynamo_db.py"
}



// ==== LANDING ZONE ===========
resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${local.identifier_prefix}-landing-zone-database"
}