data "aws_iam_policy_document" "sftp_to_s3_lambda_assume_role" {
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

resource "aws_iam_role" "sftp_to_s3_lambda" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-sftp-to-s3-lambda")
  assume_role_policy = data.aws_iam_policy_document.sftp_to_s3_lambda_assume_role.json
}

data "aws_iam_policy_document" "sftp_to_s3_lambda" {
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
      "${var.s3_target_bucket_arn}/${var.department_identifier}/*"
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    effect = "Allow"
    resources = [
      aws_iam_role.sftp_to_s3_lambda.arn
    ]
  }

  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    resources = [
      var.s3_target_bucket_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "sftp_to_s3_lambda" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-sftp-to-s3-lambda")
  policy = data.aws_iam_policy_document.sftp_to_s3_lambda.json
}

resource "aws_iam_role_policy_attachment" "sftp_to_s3_lambda" {
  role       = aws_iam_role.sftp_to_s3_lambda.name
  policy_arn = aws_iam_policy.sftp_to_s3_lambda.arn
}

