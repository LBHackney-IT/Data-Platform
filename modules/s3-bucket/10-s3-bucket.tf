resource "aws_kms_key" "key" {
  tags = var.tags

  description             = "${var.project} ${var.environment} - ${var.bucket_name} Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

locals {
  iam_arns = concat([
  for department in var.account_configuration :
  "arn:aws:iam::${department.account_to_share_data_with}:root"
  ], [
  for department in var.account_configuration :
  "arn:aws:iam::${department.account_to_share_data_with}:role/rds_export_process_role}"
  ])
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid = "AllowExternalAccountsToUseCMK"

    effect = "Allow"

    # principals {
    #   type        = "AWS"
    #   # identifiers = local.iam_arns
    #   identifiers = [
    #     "arn:aws:iam::715003523189:root",
    #     "arn:aws:iam::715003523189:role/rds_export_process_role"
    #   ]
    # }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "arn:aws:kms:::*",
    ]
  }
}

data "aws_iam_policy_document" "assume_key_role" {

  statement {
    actions =  ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      # identifiers = local.iam_arns
      identifiers = [
        "arn:aws:iam::715003523189:root",
        "arn:aws:iam::715003523189:role/rds_export_process_role"
      ]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "kms_key_role" {
  name = "iam-role-for-grant-key"

  assume_role_policy = data.aws_iam_policy_document.assume_key_role.json
}

resource "random_pet" "policy" {

}

resource "aws_iam_policy" "kms_key_policy" {
  name        = "allow_external_accounts_to_use_CMK_${random_pet.policy}"
  path        = "/"
  description = "Allow an external account to use this CMK"

  policy = data.aws_iam_policy_document.kms_key_policy.json
}

resource "aws_iam_role_policy_attachment" "kms_key_iam_policy_attachment" {
  role       = aws_iam_role.kms_key_role.name
  policy_arn = aws_iam_policy.kms_key_policy.arn
}

resource "aws_kms_grant" "kms_key" {
  name              = "kms-key-grant"
  key_id            = aws_kms_key.key.key_id
  grantee_principal = aws_iam_role.kms_key_role.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_s3_bucket" "bucket" {
  tags = var.tags

  bucket = lower("${var.identifier_prefix}-${var.bucket_identifier}")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket.bucket]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket_policy_document" {

  statement {
    sid    = "ListBucket"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = concat([
      for department in var.account_configuration :
      "arn:aws:iam::${department.account_to_share_data_with}:root"
      ], [
      for department in var.account_configuration :
      "arn:aws:iam::${department.account_to_share_data_with}:role/aws-reserved/sso.amazonaws.com/${department.iam_role_name}"
      ])
    }
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bucket.arn]
  }

  dynamic "statement" {
    for_each = var.account_configuration
    iterator = account
    content {
      sid    = "WriteAccess${account.value.account_to_share_data_with}"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${account.value.account_to_share_data_with}:root",
          "arn:aws:iam::${account.value.account_to_share_data_with}:role/aws-reserved/sso.amazonaws.com/${account.value.iam_role_name}",
        ]
      }
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
      actions   = ["s3:PutObject", "s3:PutObjectAcl"]
      resources = ["${aws_s3_bucket.bucket.arn}/${account.value["s3_read_write_directory"]}/*"]
    }
  }
  dynamic "statement" {
    for_each = var.account_configuration
    iterator = account
    content {
      sid    = "ReadAccess${account.value.account_to_share_data_with}"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${account.value.account_to_share_data_with}:root",
          "arn:aws:iam::${account.value.account_to_share_data_with}:role/aws-reserved/sso.amazonaws.com/${account.value.iam_role_name}",
        ]
      }
      actions = ["s3:GetObject"]
      resources = concat(
        [for readable_folder in account.value["s3_read_directories"]: "${aws_s3_bucket.bucket.arn}/${readable_folder}/*"],
        ["${aws_s3_bucket.bucket.arn}/${account.value["s3_read_write_directory"]}/*"]
      )
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  depends_on = [
    aws_s3_bucket.bucket,
    aws_s3_bucket_public_access_block.block_public_access]
  policy = data.aws_iam_policy_document.bucket_policy_document.json
}
