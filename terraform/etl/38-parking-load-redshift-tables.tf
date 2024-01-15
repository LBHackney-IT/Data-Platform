module "parking_load_redshift_tables" {
  count                          = local.is_live_environment && !local.is_production_environment ? 1 : 0
  source                         = "../modules/aws-lambda"
  lambda_name                    = "parking-load-redshift-tables"
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "parking-load-redshift-tables.zip"
  lambda_source_dir              = "../../lambdas/redshift_stage_and_load_tables"
  lambda_output_path             = "../../lambdas/lambda-archives/parking-load-redshift-tables.zip"

  environment_variables = {
    "REDSHIFT_CLUSTER_ID" = module.redshift[0].cluster_id
    "REDSHIFT_DBNAME"     = "data_platform"
    "REDSHIFT_IAM_ROLE"   = aws_iam_role.parking_redshift_copier[0].arn
    "SOURCE_BUCKET"       = module.refined_zone_data_source.bucket_id
    "SCHEMA_NAME"         = "parking_test"
    "SQL_FILE"            = "stage_and_load_parquet.sql"
    "SECRET_NAME"         = "parking/redshift_stage_and_load_tables_user"
  }
}

# IAM policies and role for Redshift to access S3

resource "aws_iam_role" "parking_redshift_copier" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name  = "parking_redshift_copier"
  tags  = module.tags.values
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "redshift_list_and_get_s3" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      module.refined_zone_data_source.bucket_arn,
      "${module.refined_zone_data_source.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "redshift_list_and_get_s3" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "redshift_list_and_get_s3"
  policy = data.aws_iam_policy_document.redshift_list_and_get_s3.json
}

resource "aws_iam_role_policy_attachment" "redshift_list_and_get_s3" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.parking_redshift_copier[0].name
  policy_arn = aws_iam_policy.redshift_list_and_get_s3[0].arn
}

resource "aws_redshift_cluster_iam_roles" "parking_redshift_copier" {
  count              = local.is_live_environment && !local.is_production_environment ? 1 : 0
  cluster_identifier = module.redshift[0].cluster_id
  iam_role_arns      = [aws_iam_role.parking_redshift_copier[0].arn]
}

# IAM policies and role for lambda executor

data "aws_iam_policy_document" "lambda_redshift_policy" {
  statement {
    actions = [
      "redshift-data:ExecuteStatement",
      "redshift-data:GetStatementResult",
      "redshift-data:DescribeStatement",
      "redshift-data:ListDatabases",
      "redshift-data:ListSchemas",
      "redshift-data:ListTables",
      "redshift-data:ListStatements",
      "redshift-data:CancelStatement"
    ]
    resources = [module.redshift[0].cluster_arn]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:secret:parking/redshift_stage_and_load_tables_user"

    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "lambda_redshift_policy"
  policy = data.aws_iam_policy_document.lambda_redshift_policy.json
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  tags = module.tags.values

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy[0].arn
}
