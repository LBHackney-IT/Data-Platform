// deploy lambda
resource "aws_iam_role" "iam_for_lambda" {
  provider = aws.aws_api_account

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
  provider = aws.aws_api_account

  bucket        = "data-platform-db-snapshot-scripts-${var.environment}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "handler" {
  provider = aws.aws_api_account

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
  provider = aws.aws_api_account

  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "exports.handler"
  runtime          = "nodejs14.x"
  function_name    = "rds_snapshot_to_s3_lambda"
  s3_bucket        = aws_s3_bucket.s3_deployment_artefacts.bucket
  s3_key           = aws_s3_bucket_object.handler.key
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256

  environment {
    variables = {
      IAMROLEARN = aws_iam_role.rds_export_process_role.arn,
      KMSKEYID = module.landing_zone.kms_key_arn,
      S3BUCKETNAME =  module.landing_zone.bucket_id,
    }
  }

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
          Service = "export.rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "export_bucket_policy_document" {
  provider = aws.aws_api_account
  name = "rds_export_process_policy"
  description = "A rds  export processpolicy"
  policy = jsonencode({
    "Version": "2012-10-17",
     "Statement": [
         {
             "Effect": "Allow",
             "Action": [
                 "s3:ListBucket",
                 "s3:GetBucketLocation"
             ],
             "Resource": [
                 "arn:aws:s3:::*"
             ]
         },
         {
             "Effect": "Allow",
             "Action": [
                 "s3:PutObject*",
                 "s3:GetObject*",
                 "s3:CopyObject*",
                 "s3:DeleteObject*"
             ],
             "Resource": [
                "arn:aws:s3:::data-platform-snapshot-export-test",
                "arn:aws:s3:::data-platform-snapshot-export-test/*"
             ]
         }
     ]
  })
}

resource "aws_iam_role_policy_attachment" "export_bucket_policy_attachment" {
  provider = aws.aws_api_account
  role = aws_iam_role.rds_export_process_role.name
  policy_arn = aws_iam_policy.export_bucket_policy_document.arn
}

resource "aws_sns_topic" "ingestion_topic" {
  provider = aws.aws_api_account
  name = "ingestion-topic"
}

resource "aws_sqs_queue" "ingestion_queue" {
  provider = aws.aws_api_account

  name = "ingestion-queue"
}

resource "aws_sns_topic_subscription" "ingestion_sqs_target" {
  provider = aws.aws_api_account

  topic_arn = aws_sns_topic.ingestion_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ingestion_queue.arn
}

resource "aws_lambda_permission" "with_sns" {
  provider = aws.aws_api_account

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_snapshot_to_s3_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ingestion_topic.arn
}

resource "aws_sns_topic_subscription" "lambda" {
  provider = aws.aws_api_account

  topic_arn = aws_sns_topic.ingestion_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.rds_snapshot_to_s3_lambda.arn
}
