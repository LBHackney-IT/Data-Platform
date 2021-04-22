data "aws_lambda_function" "service_api_mongodb_import" {
  provider = aws.core

  function_name = "social-care-case-viewer-mongodb-import-mosaic-${lower(var.environment)}"
}

resource "aws_iam_role" "service_api_lambda_assume_role" {
  provider = aws.core

  name = "social-care-case-viewer-mongodb-import-mosaic-${lower(var.environment)}-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  })
}

resource "aws_lambda_permission" "service_api_qlik_bucket" {
  provider = aws.core

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.service_api_mongodb_import.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.service_api_qlik.arn
}

resource "aws_s3_bucket_notification" "service_api_mongodb_import" {
  provider = aws.core

  bucket = aws_s3_bucket.service_api_qlik.id

  lambda_function {
    lambda_function_arn = data.aws_lambda_function.service_api_mongodb_import.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.service_api_qlik_bucket]
}
