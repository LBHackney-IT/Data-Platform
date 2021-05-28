data "aws_iam_policy_document" "parking_liberator_data_upload_lambda_assume_role" {
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

resource "aws_iam_role" "parking_liberator_data_upload_lambda" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-liberator-data-upload-lambda")
  assume_role_policy = data.aws_iam_policy_document.parking_liberator_data_upload_lambda_assume_role.json
}

data "aws_iam_policy_document" "parking_liberator_data_upload_lambda" {
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

  statement {
    actions = [
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      "${var.landing_zone_bucket_arn}/parking/*"
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    effect = "Allow"
    resources = [
      aws_iam_role.parking_liberator_data_upload_lambda.arn
    ]
  }

  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    resources = [
      var.landing_zone_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "parking_liberator_data_upload_lambda" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-parking-liberator-data-file-upload-lambda")
  policy = data.aws_iam_policy_document.parking_liberator_data_upload_lambda.json
}

resource "aws_iam_role_policy_attachment" "parking_liberator_data_upload_lambda" {
  role       = aws_iam_role.parking_liberator_data_upload_lambda.name
  policy_arn = aws_iam_policy.parking_liberator_data_upload_lambda.arn
}
