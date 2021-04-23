// deploy lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "lambda.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_dir = "../lambdas/rds-database-snapshot-replicator"
  output_path = "../lambdas/rds-database-snapshot-replicator/lambda_function.zip"
}

resource "aws_s3_bucket" "s3_deployment_artefacts" {
  bucket        = "data-platform-db-snapshot-script-${var.environment}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "handler" {
  bucket = aws_s3_bucket.s3_deployment_artefacts.bucket
  key    = "lambda_function.zip"
  source = data.archive_file.lambda_zip_file.output_path
  acl    = "private"
  etag   = filemd5(data.archive_file.lambda_zip_file.output_path)
  depends_on = [
    data.archive_file.lambda_zip_file
  ]
}

resource "aws_lambda_function" "rds_snapshot_to_s3_lambda" {
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "exports.handler"
  runtime          = "nodejs14.x"
  function_name    = "rds_snapshot_to_s3_lambda"
  s3_bucket        = aws_s3_bucket.s3_deployment_artefacts.bucket
  s3_key           = aws_s3_bucket_object.handler.key
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  depends_on = [
    aws_s3_bucket_object.handler,
  ]
}

resource "aws_iam_role" "rds_export_process_role" {
  provider = aws.aws_api_account
  name = "rds_export_process_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "export_bucket_policy_document" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::*"]
  }
  statement {
    sid    = "PutBucket"
    effect = "Allow"
    actions   = [
      "s3:PutObject*",
      "s3:GetObject*",
      "s3:CopyObject*",
      "s3:DeleteObject*"
    ]
    resources = [
      "arn:aws:s3:::data-platform-snapshot-export-test",
      "arn:aws:s3:::data-platform-snapshot-export-test/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "export_bucket_policy_attachment" {
  role = aws_iam_role.rds_export_process_role.name
  policy = data.aws_iam_policy_document.export_bucket_policy_document.json
}
// set up SNS topic

// set up event subscription

// create SNS trigger on Lambda
