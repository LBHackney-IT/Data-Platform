
data "aws_iam_policy_document" "file_transfer" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "transfer.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "ringo" {
  tags = module.tags.values

  name               = "${local.short_identifier_prefix}ringo-file-transfer"
  assume_role_policy = data.aws_iam_policy_document.file_transfer.json
}

data "aws_iam_policy_document" "ringo_can_write_to_landing_zone" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Put*",
      "s3:Get*"
    ]
    resources = [
      "${module.landing_zone.bucket_arn}/ringo/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      module.landing_zone.bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      module.landing_zone.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "ringo_can_write_to_landing_zone" {
  tags = module.tags.values

  name   = "${local.short_identifier_prefix}ringo-can-write-to-landing-zone"
  policy = data.aws_iam_policy_document.ringo_can_write_to_landing_zone.json
}

resource "aws_iam_role_policy_attachment" "ringo_can_write_to_landing_zone" {
  role       = aws_iam_role.ringo.name
  policy_arn = aws_iam_policy.ringo_can_write_to_landing_zone.arn
}

resource "aws_transfer_user" "ringo" {
  tags = module.tags.values

  server_id = aws_transfer_server.sftp.id
  user_name = "ringo"
  role      = aws_iam_role.ringo.arn

  home_directory_type = "PATH"
  home_directory      = "/${module.landing_zone.bucket_id}/ringo"
}

resource "aws_transfer_server" "sftp" {
  tags = merge(module.tags.values, {
    Name = "${local.short_identifier_prefix}dataplatform-sftp"
  })
  domain       = "S3"
  protocols    = ["SFTP"]
  logging_role = aws_iam_role.file_transfer.arn
}

resource "aws_iam_role" "file_transfer" {
  tags = module.tags.values

  name               = "${local.short_identifier_prefix}file-transfer"
  assume_role_policy = data.aws_iam_policy_document.file_transfer.json
}

data "aws_iam_policy_document" "file_transfer_can_write_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "file_transfer_can_write_logs" {
  tags = module.tags.values

  name   = "${local.short_identifier_prefix}file-transfer-can-write-logs"
  policy = data.aws_iam_policy_document.file_transfer_can_write_logs.json
}

resource "aws_iam_role_policy_attachment" "file_transfer_can_write_logs" {
  role       = aws_iam_role.file_transfer.name
  policy_arn = aws_iam_policy.file_transfer_can_write_logs.arn
}

#dummy comment to trigger a plan
