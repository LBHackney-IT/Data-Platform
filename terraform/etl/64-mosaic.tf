# IAM task role and permissions for Mosaic ECS ingestion to read credentials and shared scripts, and upload raw data.
data "aws_s3_bucket" "mosaic_etl_scripts" {
  bucket = "${local.identifier_prefix}-mwaa-etl-scripts-bucket"
}

data "aws_kms_key" "mosaic_etl_scripts" {
  key_id = "alias/mwaa-key"
}

data "aws_iam_policy_document" "mosaic_ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.data_platform.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${var.aws_deploy_region}:${data.aws_caller_identity.data_platform.account_id}:*"]
    }
  }
}

resource "aws_iam_role" "mosaic_ecs_task" {
  name               = "${local.identifier_prefix}-mosaic-ecs-task-role"
  description        = "Task role for shared Mosaic SQL Server ingestion."
  assume_role_policy = data.aws_iam_policy_document.mosaic_ecs_assume_role.json
  tags               = module.tags.values
}

data "aws_iam_policy_document" "mosaic_ingestion" {
  statement {
    sid = "WriteMosaicRawData"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${module.raw_zone_data_source.bucket_arn}/projects/mosaic/*"]
  }

  statement {
    sid       = "ListSharedIngestionScripts"
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.mosaic_etl_scripts.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["shared", "shared/*"]
    }
  }

  statement {
    sid       = "ReadSharedIngestionScripts"
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.mosaic_etl_scripts.arn}/shared/*"]
  }

  statement {
    sid       = "ReadMosaicCredentials"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.mosaic.arn]
  }

  statement {
    sid       = "EncryptMosaicRawData"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [module.raw_zone_data_source.kms_key_arn]
  }

  statement {
    sid     = "DecryptScriptsAndCredentials"
    actions = ["kms:Decrypt"]
    resources = [
      data.aws_kms_key.mosaic_etl_scripts.arn,
      data.aws_kms_key.secrets_manager_key.arn,
    ]
  }

}

resource "aws_iam_policy" "mosaic_ingestion" {
  name        = "${local.identifier_prefix}-mosaic-ingestion"
  description = "Read Mosaic credentials and shared scripts, and upload raw data."
  policy      = data.aws_iam_policy_document.mosaic_ingestion.json
  tags        = module.tags.values
}

resource "aws_iam_role_policy_attachment" "mosaic_ingestion" {
  role       = aws_iam_role.mosaic_ecs_task.name
  policy_arn = aws_iam_policy.mosaic_ingestion.arn
}
