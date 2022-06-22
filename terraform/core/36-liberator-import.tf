
module "liberator_data_storage" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Liberator Data Storage"
  bucket_identifier              = "liberator-data-storage"
  role_arns_to_share_access_with = var.environment == "stg" && var.copy_liberator_to_pre_prod_lambda_execution_role != null ? [var.copy_liberator_to_pre_prod_lambda_execution_role] : []
}

module "liberator_dump_to_rds_snapshot" {
  count = local.is_live_environment ? 1 : 0

  source                     = "../modules/sql-to-rds-snapshot"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  is_live_environment        = local.is_live_environment
  instance_name              = "${local.short_identifier_prefix}liberator-to-rds-snapshot"
  watched_bucket_name        = module.liberator_data_storage.bucket_id
  watched_bucket_kms_key_arn = module.liberator_data_storage.kms_key_arn
  aws_subnet_ids             = data.aws_subnet_ids.network.ids
  ecs_cluster_arn            = aws_ecs_cluster.workers.arn
}

module "liberator_db_snapshot_to_s3" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/db-snapshot-to-s3"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = "${local.identifier_prefix}-dp"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  zone_kms_key_arn               = module.landing_zone.kms_key_arn
  zone_bucket_arn                = module.landing_zone.bucket_arn
  zone_bucket_id                 = module.landing_zone.bucket_id
  service_area                   = "parking"
  rds_instance_ids               = [for item in module.liberator_dump_to_rds_snapshot : item.rds_instance_id]
  workflow_name                  = aws_glue_workflow.parking_liberator_data.name
  workflow_arn                   = aws_glue_workflow.parking_liberator_data.arn
}

# Move .zip in production to pre production

# Cloudwatch event target
resource "aws_lambda_permission" "allow_cloudwatch_to_call_liberator_prod_to_pre_prod_lambda" {
  count         = local.is_production_environment ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.liberator_prod_to_pre_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.liberator_dump_to_rds_snapshot[0].cloudwatch_event_rule_arn
}

resource "aws_cloudwatch_event_target" "run_liberator_prod_to_pre_prod_lambda" {
  count     = local.is_production_environment ? 1 : 0
  target_id = "copy-liberator-zip-from-prod-to-pre-prod-lambda"
  arn       = aws_lambda_function.liberator_prod_to_pre_prod[0].arn

  rule = module.liberator_dump_to_rds_snapshot[0].cloudwatch_event_rule_name
}

# Lambda execution role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "liberator_prod_to_pre_prod_lambda" {
  count              = local.is_production_environment ? 1 : 0
  tags               = module.tags.values
  name               = "${local.short_identifier_prefix}liberator-prod-to-pre-prod-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "move_liberator_to_pre_prod" {
  count = local.is_production_environment ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  # get from liberator storage bucket in production
  statement {
    actions = [
      "kms:*",
      "s3:Get*",
      "s3:List*",
    ]
    effect = "Allow"
    resources = [
      "${module.liberator_data_storage.bucket_arn}*",
      module.liberator_data_storage.kms_key_arn
    ]
  }

  # put into liberator storage bucket in pre-production
  statement {
    actions = [
      "kms:*",
      "s3:List*",
      "s3:Put*"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::dataplatform-stg-liberator-data-storage*",
      var.pre_production_liberator_data_storage_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "move_liberator_to_pre_prod" {
  count = local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  name   = "${local.short_identifier_prefix}move-libertor-to-pre-prod"
  policy = data.aws_iam_policy_document.move_liberator_to_pre_prod[0].json
}

resource "aws_iam_role_policy_attachment" "move_liberator_to_pre_prod" {
  count      = local.is_production_environment ? 1 : 0
  role       = aws_iam_role.liberator_prod_to_pre_prod_lambda[0].name
  policy_arn = aws_iam_policy.move_liberator_to_pre_prod[0].arn
}

#  Lambda function 
data "archive_file" "liberator_prod_to_pre_prod" {
  type        = "zip"
  source_dir  = "../../lambdas/liberator_prod_to_pre_prod"
  output_path = "../../lambdas/liberator_prod_to_pre_prod.zip"
}

resource "aws_s3_bucket_object" "liberator_prod_to_pre_prod" {
  bucket      = module.lambda_artefact_storage.bucket_id
  key         = "liberator_prod_to_pre_prod.zip"
  source      = data.archive_file.liberator_prod_to_pre_prod.output_path
  acl         = "private"
  source_hash = data.archive_file.liberator_prod_to_pre_prod.output_md5
}

resource "aws_lambda_function_event_invoke_config" "liberator_prod_to_pre_prod" {
  count                  = local.is_production_environment ? 1 : 0
  function_name          = aws_lambda_function.liberator_prod_to_pre_prod[0].function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"
}

resource "aws_lambda_function" "liberator_prod_to_pre_prod" {
  count = local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  role             = aws_iam_role.liberator_prod_to_pre_prod_lambda[0].arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  function_name    = "${local.short_identifier_prefix}liberator-prod-to-pre-prod"
  s3_bucket        = module.lambda_artefact_storage.bucket_id
  s3_key           = aws_s3_bucket_object.liberator_prod_to_pre_prod.key
  source_code_hash = data.archive_file.liberator_prod_to_pre_prod.output_base64sha256
  timeout          = "60"

  environment {
    variables = {
      "TARGET_BUCKET_ID" = "dataplatform-stg-liberator-data-storage",
      "TARGET_PREFIX"    = ""
    }
  }
}