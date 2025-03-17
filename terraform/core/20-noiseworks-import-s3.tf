module "noiseworks_data_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Noiseworks Data Storage"
  bucket_identifier          = "noiseworks-data-storage"
  include_backup_policy_tags = false
}

# Noiseworks User

resource "aws_iam_user" "noiseworks_user" {
  name = "${local.short_identifier_prefix}noiseworks-user"

  tags = module.tags.values
}

resource "aws_iam_access_key" "noiseworks_access_key" {
  user = aws_iam_user.noiseworks_user.name
}

resource "aws_iam_user_policy" "noiseworks_user_policy" {
  name = "${local.short_identifier_prefix}noiseworks-user-policy"
  user = aws_iam_user.noiseworks_user.name

  policy = data.aws_iam_policy_document.noiseworks_can_write_to_s3.json
}

data "aws_iam_policy_document" "noiseworks_can_write_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      module.noiseworks_data_storage.bucket_arn
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
      "${module.noiseworks_data_storage.bucket_arn}/*"
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
      module.noiseworks_data_storage.kms_key_arn
    ]
  }
}

resource "aws_secretsmanager_secret" "noiseworks_user_private_key" {
  tags = module.tags.values

  name_prefix = "${local.short_identifier_prefix}noiseworks-user-private-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

locals {
  noisework_access_keys = {
    "Access Key ID"     = aws_iam_access_key.noiseworks_access_key.id
    "Secret Access key" = aws_iam_access_key.noiseworks_access_key.secret
  }
}

resource "aws_secretsmanager_secret_version" "noiseworks_user_private_key_version" {
  secret_id     = aws_secretsmanager_secret.noiseworks_user_private_key.id
  secret_string = jsonencode(local.noisework_access_keys)
}

# Moving data to Raw Zone

data "aws_iam_policy_document" "s3_access_to_noiseworks_data" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      module.noiseworks_data_storage.bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:ListObjectsV2",
    ]
    resources = [
      "${module.noiseworks_data_storage.bucket_arn}/*"
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
      module.noiseworks_data_storage.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "s3_access_to_noiseworks_data" {
  tags   = module.tags.values
  name   = "${local.short_identifier_prefix}s3-access-to-noiseworks-data"
  policy = data.aws_iam_policy_document.s3_access_to_noiseworks_data.json
}

resource "aws_iam_role_policy_attachment" "env_enforcement_role_can_get_noiseworks_data" {
  role       = module.department_env_enforcement.glue_role_name
  policy_arn = aws_iam_policy.s3_access_to_noiseworks_data.arn
}
