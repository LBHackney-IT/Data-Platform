resource "aws_iam_user" "database_migration" {
  name          = "${local.short_identifier_prefix}database_migration"
  force_destroy = !local.is_live_environment
  tags          = module.tags.values
}

resource "aws_iam_user_policy" "database_migration_user_policy" {
  name   = "${local.short_identifier_prefix}database_migration_user_policy"
  user   = aws_iam_user.database_migration.name
  policy = data.aws_iam_policy_document.database_migration_custom_policy.json
}

data "aws_iam_policy_document" "database_migration_custom_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "${module.raw_zone.bucket_arn}/*",
      "${module.refined_zone.bucket_arn}/*",
      "${module.trusted_zone.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      # "kms:GenerateDataKey",
    ]
    resources = [
      module.raw_zone.kms_key_arn,
      module.refined_zone.kms_key_arn,
      module.trusted_zone.kms_key_arn
    ]
  }

  // Add new statement for full Redshift access.
  statement {
    effect = "Allow"
    actions = [
      "redshift:*",
    ]
    resources = [
      "*" // will adjust this based on specific Redshift resource ARNs later
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${var.aws_deploy_region}:${var.aws_deploy_account_id}:secret:/${module.department_data_and_insight.identifier}/*"]
  }
}
