resource "aws_iam_user" "liberator_user" {
  name = "${local.short_identifier_prefix}liberator-user"

  tags = module.tags.values
}

resource "aws_iam_access_key" "liberator_access_key" {
  user = aws_iam_user.liberator_user.name
}

resource "aws_iam_user_policy" "liberator_user_policy" {
  name = "${local.short_identifier_prefix}liberator-user-policy"
  user = aws_iam_user.liberator_user.name

  policy = data.aws_iam_policy_document.liberator_can_write_to_s3.json
}

data "aws_iam_policy_document" "liberator_can_write_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      module.liberator_data_storage.bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:ListObjectsV2",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${module.liberator_data_storage.bucket_arn}/parking/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = [
      module.liberator_data_storage.kms_key_arn
    ]
  }
}

resource "aws_secretsmanager_secret" "liberator_user_private_key" {
  tags = module.tags.values

  name_prefix = "${local.short_identifier_prefix}liberator-user-private-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret_version" "liberator_user_private_key_version" {
  secret_id = aws_secretsmanager_secret.liberator_user_private_key.id
  secret_string = jsonencode({
    "Access Key ID"     = aws_iam_access_key.liberator_access_key.id
    "Secret Access key" = aws_iam_access_key.liberator_access_key.secret
  })
}
