# ECS task role for shared Synergy SQL Server ingestion.
data "aws_s3_bucket" "synergy_etl_scripts" {
  bucket = "${local.identifier_prefix}-mwaa-etl-scripts-bucket"
}

data "aws_kms_key" "synergy_etl_scripts" {
  key_id = "alias/mwaa-key"
}

data "aws_iam_policy_document" "synergy_ecs_assume_role" {
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

resource "aws_iam_role" "synergy_ecs_task" {
  name               = "${local.identifier_prefix}-synergy-ecs-task-role"
  description        = "Task role for shared Synergy SQL Server ingestion."
  assume_role_policy = data.aws_iam_policy_document.synergy_ecs_assume_role.json
  tags               = module.tags.values
}

data "aws_iam_policy_document" "synergy_ingestion" {
  statement {
    sid = "WriteSynergyRawData"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${module.raw_zone_data_source.bucket_arn}/projects/synergy/*"]
  }

  statement {
    sid       = "ListSynergyRawData"
    actions   = ["s3:ListBucket"]
    resources = [module.raw_zone_data_source.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["projects/synergy", "projects/synergy/*"]
    }
  }

  statement {
    sid       = "LocateSynergyRawBucket"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.raw_zone_data_source.bucket_arn]
  }

  statement {
    sid = "ManageSynergyRawCatalog"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:UpdatePartition",
      "glue:DeletePartition",
      "glue:BatchCreatePartition",
      "glue:BatchUpdatePartition",
      "glue:BatchDeletePartition",
    ]
    resources = [
      "arn:aws:glue:${var.aws_deploy_region}:${data.aws_caller_identity.data_platform.account_id}:catalog",
      aws_glue_catalog_database.hackney_synergy_live.arn,
      aws_glue_catalog_database.hackney_casemanagement_live.arn,
      "arn:aws:glue:${var.aws_deploy_region}:${data.aws_caller_identity.data_platform.account_id}:table/${aws_glue_catalog_database.hackney_synergy_live.name}/*",
      "arn:aws:glue:${var.aws_deploy_region}:${data.aws_caller_identity.data_platform.account_id}:table/${aws_glue_catalog_database.hackney_casemanagement_live.name}/*",
    ]
  }

  statement {
    sid       = "ListSynergyScripts"
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.synergy_etl_scripts.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["shared", "shared/*"]
    }
  }

  statement {
    sid       = "ReadSynergyScripts"
    actions   = ["s3:GetObject"]
    resources = ["${data.aws_s3_bucket.synergy_etl_scripts.arn}/shared/*"]
  }

  statement {
    sid       = "ReadSynergyCredentials"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.synergy_conn.arn]
  }

  statement {
    sid       = "EncryptSynergyRawData"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [module.raw_zone_data_source.kms_key_arn]
  }

  statement {
    sid     = "DecryptSynergyScriptsAndCredentials"
    actions = ["kms:Decrypt"]
    resources = [
      data.aws_kms_key.synergy_etl_scripts.arn,
      data.aws_kms_key.secrets_manager_key.arn,
    ]
  }
}

resource "aws_iam_policy" "synergy_ingestion" {
  name        = "${local.identifier_prefix}-synergy-ingestion"
  description = "Read Synergy credentials and scripts, and manage raw data."
  policy      = data.aws_iam_policy_document.synergy_ingestion.json
  tags        = module.tags.values
}

resource "aws_iam_role_policy_attachment" "synergy_ingestion" {
  role       = aws_iam_role.synergy_ecs_task.name
  policy_arn = aws_iam_policy.synergy_ingestion.arn
}
