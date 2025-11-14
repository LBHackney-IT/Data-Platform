# Lambda function to automatically create/delete Glue Catalog tables
# when CSV files are uploaded/deleted in the user_uploads bucket

data "aws_iam_policy_document" "csv_to_glue_catalog_lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "csv_to_glue_catalog_lambda_execution" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetTables",
    ]
    # Currently only scoped to parking. This can be scaled up to support other departments.
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:database/parking_user_uploads_db",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:table/parking_user_uploads_db/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "${module.user_uploads_data_source.bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [
      module.user_uploads_data_source.kms_key_arn,
    ]
  }

}

resource "aws_iam_role" "csv_to_glue_catalog_lambda" {
  name               = "${local.short_identifier_prefix}csv-to-glue-catalog-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.csv_to_glue_catalog_lambda_assume_role.json
  tags               = module.tags.values
}

resource "aws_iam_policy" "csv_to_glue_catalog_lambda_execution" {
  name   = "${local.short_identifier_prefix}csv-to-glue-catalog-lambda-execution"
  policy = data.aws_iam_policy_document.csv_to_glue_catalog_lambda_execution.json
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "csv_to_glue_catalog_lambda_execution" {
  role       = aws_iam_role.csv_to_glue_catalog_lambda.name
  policy_arn = aws_iam_policy.csv_to_glue_catalog_lambda_execution.arn
}

module "csv_to_glue_catalog_lambda" {
  source                         = "../modules/aws-lambda"
  lambda_name                    = "csv-to-glue-catalog"
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "csv_to_glue_catalog.zip"
  lambda_source_dir              = "../../lambdas/csv_to_glue_catalog"
  lambda_output_path             = "../../lambdas/csv_to_glue_catalog.zip"
  identifier_prefix              = local.short_identifier_prefix
  lambda_role_arn                = aws_iam_role.csv_to_glue_catalog_lambda.arn
  lambda_timeout                 = 300
  lambda_memory_size             = 256
  description                    = "Automatically creates/deletes Glue Catalog tables when CSV files are uploaded/deleted in user_uploads bucket"
  environment_variables = {
    GLUE_DATABASE_NAME = "parking_user_uploads_db"
  }
  tags = module.tags.values
}

# S3 bucket notification to trigger Lambda on CSV file uploads/deletions
resource "aws_s3_bucket_notification" "user_uploads_csv_notification" {
  bucket = module.user_uploads_data_source.bucket_id

  lambda_function {
    lambda_function_arn = module.csv_to_glue_catalog_lambda.lambda_function_arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix       = "parking/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke_csv_to_glue_catalog]
}

resource "aws_lambda_permission" "allow_s3_to_invoke_csv_to_glue_catalog" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.csv_to_glue_catalog_lambda.lambda_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.user_uploads_data_source.bucket_arn
}
