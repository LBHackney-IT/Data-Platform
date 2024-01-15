locals {
  email_list = split(",", var.email_list)
}

resource "aws_sns_topic" "s3_bucket_notifications" {
  name   = var.name
  policy = data.aws_iam_policy_document.topic.json
}

resource "aws_s3_bucket_notification" "s3_bucket_notifications" {
  bucket = var.bucket_id

  lambda_function {
    lambda_function_arn = module.lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.filter_prefix
    filter_suffix       = var.filter_suffix
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_sns_topic_subscription" "s3_bucket_notifications" {
  for_each  = toset(local.email_list)
  topic_arn = aws_sns_topic.s3_bucket_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

data "aws_iam_policy_document" "topic" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:${var.name}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.bucket_arn]
    }
  }
}

module "lambda_function" {
  source                         = "../aws-lambda"
  lambda_name                    = var.name
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  s3_key                         = "${var.name}.zip"
  lambda_source_dir              = "../../lambdas/publish_file_upload_to_sns_topic"
  lambda_output_path             = "../../lambdas/${var.name}.zip"
  lambda_role_arn                = aws_iam_role.iam_for_lambda.arn
  environment_variables = {
    "TOPIC_ARN" = aws_sns_topic.s3_bucket_notifications.arn
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

data "aws_iam_policy_document" "sns_publish" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.s3_bucket_notifications.arn]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = var.name
  description = "Policy for ${var.name} lambda"
  policy      = data.aws_iam_policy_document.sns_publish.json
}

resource "aws_iam_role_policy_attachment" "sns_publish" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

