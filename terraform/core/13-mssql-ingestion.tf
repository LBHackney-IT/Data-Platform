module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "academy-benefits-housing-needs-and-revenues"
  jdbc_connection_url         = "jdbc:sqlserver://10.120.23.22:1433;databaseName=LBHALiveRBViews"
  jdbc_connection_description = "JDBC connection to Academy Production Insights LBHALiveRBViews database"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  database_secret_name        = "database-credentials/lbhaliverbviews-benefits-housing-needs-revenues"
  identifier_prefix           = local.short_identifier_prefix
  create_workflow             = false
}

resource "aws_glue_catalog_database" "landing_zone_academy" {
  name = "${local.short_identifier_prefix}academy-landing-zone"

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  table_filter_expressions = local.is_live_environment ? {
    core_hbrent_s    = "^lbhaliverbviews_core_hbrent[s].*",
    core_hbrent_hbc  = "^lbhaliverbviews_core_hbc.*",
    core_hbuc        = "^lbhaliverbviews_core_hbuc.*",
    core_hbrentclaim = "^lbhaliverbviews_core_hbrentclaim",
    core_hbrenttrans = "^lbhaliverbviews_core_hbrenttrans",
    core_hbrent_tsc  = "^lbhaliverbviews_core_hbrent[^tsc].*",
    core_hbmember    = "^lbhaliverbviews_core_hbmember",
    core_hbincome    = "^lbhaliverbviews_core_hbincome",
    core_hb          = "^lbhaliverbviews_core_hb[abdefghjklnopsw]",
    core_ct_dt       = "^lbhaliverbviews_core_ct[dt].*",
    current_ctax     = "^lbhaliverbviews_current_ctax.*",
    current_hbn      = "^lbhaliverbviews_current_[hbn].*",
    core_ct          = "^lbhaliverbviews_core_ct[abcefghijklmnopqrsvw].*",
    core_recov_event = "^lbhaliverbviews_core_recov_event",
    mix              = "(^lbhaliverbviews_core_cr.*|^lbhaliverbviews_core_[ins].*|^lbhaliverbviews_xdbvw.*|^lbhaliverbviews_current_im.*)"
  } : {}
  academy_ingestion_max_concurrent_runs = local.is_live_environment ? length(local.table_filter_expressions) : 1
}

resource "aws_glue_crawler" "academy_revenues_and_benefits_housing_needs_landing_zone" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_academy.name
  name          = "${local.short_identifier_prefix}academy-revenues-benefits-housing-needs-database-ingestion"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${module.landing_zone.bucket_id}/academy/"
  }
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 3
    }
  })
}

module "copy_academy_landing_to_raw" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  job_name                        = "${local.short_identifier_prefix}Copy Academy to raw zone"
  script_s3_object_key            = aws_s3_object.copy_tables_landing_to_raw.key
  environment                     = var.environment
  pydeequ_zip_key                 = aws_s3_object.pydeequ.key
  helper_module_key               = aws_s3_object.helpers.key
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_temp_bucket_id             = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  spark_ui_output_storage_id      = module.spark_ui_output_storage.bucket_id
  glue_version                    = "4.0"
  glue_job_worker_type            = "G.2X"
  number_of_workers_for_glue_job  = 10
  glue_job_timeout                = 220
  max_concurrent_runs_of_glue_job = length(local.academy_ingestion_input.LandingToRaw)
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = ""
    "--table_filter_expression"          = ""
    "--glue_database_name_source"        = aws_glue_catalog_database.landing_zone_academy.name
    "--glue_database_name_target"        = ""
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-auto-scaling"              = "true"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--write-shuffle-files-to-s3"        = "true"
    "--write-shuffle-spills-to-s3"       = "true"
    "--conf"                             = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }

}

## Academy State Machine.

locals {
  academy_state_machine_count = local.is_live_environment ? 1 : 0
  number_of_glue_workers      = 2
  academy_table_filters       = ["^lbhaliverbviews_core_hbrent[s].*", "^lbhaliverbviews_core_hbc.*", "^lbhaliverbviews_core_hbuc.*", "^lbhaliverbviews_core_hbrentclaim", "^lbhaliverbviews_core_hbrenttrans", "^lbhaliverbviews_core_hbrent[^tsc].*", "^lbhaliverbviews_core_hbmember", "^lbhaliverbviews_core_hbincome", "^lbhaliverbviews_core_hb[abdefghjklnopsw]", "^lbhaliverbviews_core_ct[dt].*", "^lbhaliverbviews_current_ctax.*", "^lbhaliverbviews_current_[hbn].*", "^lbhaliverbviews_core_ct[abcefghijklmnopqrsvw].*", "^lbhaliverbviews_core_recov_event", "(^lbhaliverbviews_core_cr.*|^lbhaliverbviews_core_[ins].*|^lbhaliverbviews_xdbvw.*|^lbhaliverbviews_current_im.*)"]
  academy_ingestion_input = {
    TableFilters = local.academy_table_filters
    LandingToRaw = [
      {
        S3Prefix           = "revenues/",
        FilterString       = "(^lbhaliverbviews_core_(?!hb).*|^lbhaliverbviews_current_(?!hb).*|^lbhaliverbviews_xdbvw_.*)",
        GlueDatabaseTarget = module.department_revenues.raw_zone_catalog_database_name
      },
      {
        S3Prefix           = "benefits-housing-needs/",
        FilterString       = "(^lbhaliverbviews_core_hb.*|^lbhaliverbviews_current_hb.*)",
        GlueDatabaseTarget = module.department_benefits_and_housing_needs.raw_zone_catalog_database_name
      }
    ]
  }
}

module "academy_glue_job" {
  count                     = local.academy_state_machine_count
  source                    = "../modules/aws-glue-job"
  tags                      = module.tags.values
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  job_name                        = "${local.short_identifier_prefix}Academy Revs & Bens Housing Needs Database Ingestion"
  script_s3_object_key            = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  environment                     = var.environment
  pydeequ_zip_key                 = aws_s3_object.pydeequ.key
  helper_module_key               = aws_s3_object.helpers.key
  jdbc_connections                = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_temp_bucket_id             = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  spark_ui_output_storage_id      = module.spark_ui_output_storage.bucket_id
  glue_job_timeout                = 420
  glue_version                    = "4.0"
  glue_job_worker_type            = "G.1X"
  number_of_workers_for_glue_job  = local.number_of_glue_workers
  max_concurrent_runs_of_glue_job = length(local.academy_table_filters)
  job_parameters = {
    "--source_data_database"        = module.academy_mssql_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"  = "s3://${module.landing_zone.bucket_id}/academy/"
    "--s3_ingestion_details_target" = "s3://${module.landing_zone.bucket_id}/academy/ingestion-details/"
    "--table_filter_expression"     = ""
    "--conf"                        = "spark.sql.legacy.timeParserPolicy=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.int96RebaseModeInWrite=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInRead=LEGACY --conf spark.sql.legacy.parquet.datetimeRebaseModeInWrite=LEGACY"
  }
}

data "template_file" "academy_state_machine_definition" {
  count    = local.academy_state_machine_count
  template = file("../../state-machine-definitions/academy_ingestion.asl.json")
  vars = {
    SubnetIds                      = local.instance_subnet_id,
    MaxConcurrencyLambdaArn        = module.max_concurrency_lambda[0].lambda_function_arn,
    NumberOfGlueWorkers            = local.number_of_glue_workers,
    IngestionGlueJobName           = module.academy_glue_job[0].job_name,
    AcademyCrawlerName             = aws_glue_crawler.academy_revenues_and_benefits_housing_needs_landing_zone.name,
    AcademyLandingToRawGlueJobName = module.copy_academy_landing_to_raw[0].job_name
  }
}

module "academy_state_machine" {
  count             = local.academy_state_machine_count
  tags              = module.tags.values
  source            = "../modules/aws-step-functions"
  name              = "academy-revs-and-bens-housing-needs-database-ingestion"
  identifier_prefix = local.short_identifier_prefix
  role_arn          = aws_iam_role.academy_step_functions_role[0].arn
  definition        = data.template_file.academy_state_machine_definition[0].rendered
}

module "max_concurrency_lambda" {
  count                          = local.academy_state_machine_count
  source                         = "../modules/aws-lambda"
  tags                           = module.tags.values
  lambda_name                    = "academy-max-concurrency"
  identifier_prefix              = local.short_identifier_prefix
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  s3_key                         = "academy-revs-and-bens-housing-needs-database-ingestion-max-concurrency.zip"
  lambda_source_dir              = "../../lambdas/calculate_max_concurrency"
  lambda_output_path             = "../../lambdas/calculate_max_concurrency/max-concurrency.zip"
  runtime                        = "python3.8"
}

resource "aws_iam_role" "academy_step_functions_role" {
  count              = local.academy_state_machine_count
  name               = "${local.short_identifier_prefix}academy-step-functions-role"
  tags               = module.tags.values
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role_policy.json
}

data "aws_iam_policy_document" "step_functions_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "academy_step_functions_policy" {
  count = local.academy_state_machine_count
  statement {
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun",
      "glue:StartCrawler"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [module.max_concurrency_lambda[0].lambda_function_arn]
  }

  statement {
    actions = [
      "ec2:DescribeSubnets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "academy_step_functions_policy" {
  count  = local.academy_state_machine_count
  name   = "${local.short_identifier_prefix}academy-step-functions-policy"
  tags   = module.tags.values
  policy = data.aws_iam_policy_document.academy_step_functions_policy[0].json
}

resource "aws_iam_policy_attachment" "academy_step_functions_policy_attachment" {
  count      = local.academy_state_machine_count
  name       = "${local.short_identifier_prefix}academy-step-functions-policy-attachment"
  policy_arn = aws_iam_policy.academy_step_functions_policy[0].arn
  roles      = [aws_iam_role.academy_step_functions_role[0].name]
}

resource "aws_cloudwatch_event_rule" "academy_state_machine_trigger" {
  count               = local.academy_state_machine_count
  name                = "${local.short_identifier_prefix}academy-state-machine-trigger"
  tags                = module.tags.values
  description         = "Trigger the Academy State Machine every weekday at 1am"
  schedule_expression = "cron(0 1 ? * MON-FRI *)"
  is_enabled          = true
}

resource "aws_cloudwatch_event_target" "academy_state_machine_trigger" {
  count    = local.academy_state_machine_count
  rule     = aws_cloudwatch_event_rule.academy_state_machine_trigger[0].name
  arn      = module.academy_state_machine[0].arn
  role_arn = aws_iam_role.academy_cloudwatch_execution_role[0].arn
  input    = jsonencode(local.academy_ingestion_input)
}

resource "aws_iam_role" "academy_cloudwatch_execution_role" {
  count              = local.academy_state_machine_count
  name               = "${local.short_identifier_prefix}academy-cloudwatch-execution-role"
  tags               = module.tags.values
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_role_policy.json
}

data "aws_iam_policy_document" "cloudwatch_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudwatch_execution_policy" {
  count = local.academy_state_machine_count
  statement {
    actions = [
      "states:StartExecution"
    ]
    resources = [module.academy_state_machine[0].arn]
  }
}

resource "aws_iam_policy_attachment" "academy_cloudwatch_execution_policy_attachment" {
  count      = local.academy_state_machine_count
  name       = "${local.short_identifier_prefix}academy-cloudwatch-execution-policy-attachment"
  policy_arn = aws_iam_policy.academy_cloudwatch_execution_policy[0].arn
  roles      = [aws_iam_role.academy_cloudwatch_execution_role[0].name]
}

resource "aws_iam_policy" "academy_cloudwatch_execution_policy" {
  count  = local.academy_state_machine_count
  name   = "${local.short_identifier_prefix}academy-cloudwatch-execution-policy"
  tags   = module.tags.values
  policy = data.aws_iam_policy_document.cloudwatch_execution_policy[0].json
}
