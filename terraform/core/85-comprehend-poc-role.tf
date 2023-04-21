data "aws_iam_policy_document" "comprehend_assume_role" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "comprehend.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "comprehend_role" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  name               = "${local.short_identifier_prefix}comprehend-poc"
  assume_role_policy = data.aws_iam_policy_document.comprehend_assume_role[0].json
}

resource "aws_iam_policy" "comprehend_policy" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  name   = "${local.short_identifier_prefix}comprehend-poc"
  policy = data.aws_iam_policy_document.comprehend_policy[0].json
}

resource "aws_iam_policy_attachment" "name" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name       = "${local.short_identifier_prefix}comprehend-poc"
  roles      = [aws_iam_role.comprehend_role[0].name]
  policy_arn = aws_iam_policy.comprehend_policy[0].arn
}

data "aws_iam_policy_document" "comprehend_policy" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0

  statement {
    sid    = "AllowReadAccessToLandingZoneLocation"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:ListBucket"
    ]
    resources = [
      module.landing_zone.bucket_arn,
      "${module.landing_zone.bucket_arn}/data-and-insight/manual/*"
    ]
  }

  statement {
    effect = "Allow"
    sid    = "AllowAccessToLandingZoneKey"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = [
      module.landing_zone.kms_key_arn
    ]
  }

  statement {
    sid    = "AllowWriteAccessToRawZoneLocation"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/data-and-insight/testing/*"
    ]
  }

  statement {
    effect = "Allow"
    sid    = "AllowAccessToRawZoneKey"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*"
    ]
    resources = [
      module.raw_zone.kms_key_arn
    ]
  }

  statement {
    effect = "Allow"
    sid    = "AllowFullAccessToComprehend"
    actions = [
      "comprehend:*"
    ]
    resources = ["*"]
  }
}
