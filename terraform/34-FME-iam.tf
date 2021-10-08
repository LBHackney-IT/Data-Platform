resource "aws_iam_user" "fme_user" {
  name = "${local.short_identifier_prefix}fme_user"

  tags = module.tags.values
}

resource "aws_iam_access_key" "fme_access_key" {
  user = aws_iam_user.fme_user.name
}

resource "aws_iam_user_policy" "fme_user_policy" {
  name = "${local.short_identifier_prefix}fme-user-policy"
  user = aws_iam_user.fme_user.name
  policy = data.aws_iam_policy_document.fme_can_write_to_s3_and_athena.json
}

data "aws_iam_policy_document" "fme_can_write_to_s3_and_athena" {
  statement {
    effect = "Allow"
    actions = [
      "S3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.raw_zone.bucket_arn}/",
      "${module.refined_zone.bucket_arn}/",
      "${module.trusted_zone.bucket_arn}/"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${module.refined_zone.bucket_arn}/*",
      "${module.trusted_zone.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${module.raw_zone.bucket_arn}/*",
      "${module.refined_zone.bucket_arn}/*",
      "${module.trusted_zone.bucket_arn}/*"

    ]
  }
}