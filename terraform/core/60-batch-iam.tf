#===============================================================================
# S3 Batch Copy IAM Policy and Role
#===============================================================================

data "aws_iam_policy_document" "batch_s3_copy_service_role" {
  statement {
    sid    = "S3BatchJobRawZoneObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${module.raw_zone.bucket_arn}/*"
    ]
  }

  statement {
    sid    = "S3BatchJobRawZoneBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      module.raw_zone.bucket_arn
    ]
  }

  statement {
    sid    = "S3BatchJobRefinedZoneObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${module.refined_zone.bucket_arn}/*"
    ]
  }

  statement {
    sid    = "S3BatchJobRefinedZoneBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      module.refined_zone.bucket_arn
    ]
  }

  statement {
    sid    = "S3BatchJobTrustedZoneObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${module.trusted_zone.bucket_arn}/*"
    ]
  }

  statement {
    sid    = "S3BatchJobTrustedZoneBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      module.trusted_zone.bucket_arn
    ]
  }

  statement {
    sid    = "KMSAccessForRawZone"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.raw_zone.kms_key_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_deploy_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${module.raw_zone.bucket_arn}/*"]
    }
  }

  statement {
    sid    = "KMSAccessForRefinedZone"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.refined_zone.kms_key_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_deploy_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${module.refined_zone.bucket_arn}/*"]
    }
  }

  statement {
    sid    = "KMSAccessForTrustedZone"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.trusted_zone.kms_key_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_deploy_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${module.trusted_zone.bucket_arn}/*"]
    }
  }

  statement {
    sid = "S3BatchJobManifestAndReportAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.admin_bucket.bucket_arn}/*"]
  }

  statement {
    sid = "KMSAccessForAdminBucket"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.admin_bucket.kms_key_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_deploy_region}.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${module.admin_bucket.bucket_arn}/*"]
    }
  }
}

resource "aws_iam_policy" "batch_s3_copy_policy" {
  name        = "${local.identifier_prefix}-batch-s3-copy-policy"
  description = "Policy for S3 batch copy operations"
  policy      = data.aws_iam_policy_document.batch_s3_copy_service_role.json

  tags = module.tags.values
}

resource "aws_iam_role" "batch_s3_copy_role" {
  name = "${local.identifier_prefix}-batch-s3-copy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })

  tags = module.tags.values
}

resource "aws_iam_role_policy_attachment" "batch_s3_copy_policy_attachment" {
  role       = aws_iam_role.batch_s3_copy_role.name
  policy_arn = aws_iam_policy.batch_s3_copy_policy.arn
}

data "aws_iam_policy_document" "batch_service_policy" {
  statement {
    sid    = "BatchServicePermissions"
    effect = "Allow"
    actions = [
      "batch:DescribeJobs",
      "batch:ListJobs",
      "batch:SubmitJob",
      "batch:TerminateJob"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSTaskExecution"
    effect = "Allow"
    actions = [
      "ecs:RunTask",
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECSTaskExecutionRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.batch_s3_copy_role.arn
    ]
  }
}

resource "aws_iam_policy" "batch_service_policy" {
  name        = "${local.identifier_prefix}-batch-service-policy"
  description = "Policy for AWS Batch service permissions"
  policy      = data.aws_iam_policy_document.batch_service_policy.json

  tags = module.tags.values
}

resource "aws_iam_role_policy_attachment" "batch_service_policy_attachment" {
  role       = aws_iam_role.batch_s3_copy_role.name
  policy_arn = aws_iam_policy.batch_service_policy.arn
}