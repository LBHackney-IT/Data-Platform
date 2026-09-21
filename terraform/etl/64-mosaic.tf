# IAM task role and permissions for Mosaic ECS ingestion and transformations.
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
  description        = "Task role for Mosaic SQL Server ingestion and transformations."
  assume_role_policy = data.aws_iam_policy_document.mosaic_ecs_assume_role.json
  tags               = module.tags.values
}

data "aws_iam_policy_document" "mosaic_ingestion" {
  statement {
    sid = "WriteMosaicRawData"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
    ]
    resources = ["${module.raw_zone_data_source.bucket_arn}/projects/mosaic/*"]
  }

  statement {
    sid       = "ListMosaicRawData"
    actions   = ["s3:ListBucket"]
    resources = [module.raw_zone_data_source.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["projects/mosaic/*"]
    }
  }

  statement {
    sid = "ManageMosaicRawCatalog"
    actions = [
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetPartitions",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
    ]
    resources = [
      "arn:aws:glue:${var.aws_deploy_region}:${data.aws_caller_identity.data_platform.account_id}:catalog",
      aws_glue_catalog_database.mosaic_raw.arn,
      "arn:aws:glue:${var.aws_deploy_region}:${data.aws_caller_identity.data_platform.account_id}:table/${aws_glue_catalog_database.mosaic_raw.name}/*",
    ]
  }

  statement {
    sid       = "ListMosaicScripts"
    actions   = ["s3:ListBucket"]
    resources = [data.aws_s3_bucket.mosaic_etl_scripts.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["shared", "shared/*", "projects/mosaic/*"]
    }
  }

  statement {
    sid     = "ReadMosaicScripts"
    actions = ["s3:GetObject"]
    resources = [
      "${data.aws_s3_bucket.mosaic_etl_scripts.arn}/shared/*",
      "${data.aws_s3_bucket.mosaic_etl_scripts.arn}/projects/mosaic/*",
      "arn:aws:s3:::${local.identifier_prefix}-mwaa-bucket/dags/projects/mosaic/transformations/*",
    ]
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

# Mosaic transformations run in ECS and read all tables in the source databases.
resource "aws_iam_role_policy" "mosaic_transformations" {
  name = "${local.identifier_prefix}-mosaic-transformations"
  role = aws_iam_role.mosaic_ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RunMosaicQueries"
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetWorkGroup",
          "athena:GetQueryResults",
          "athena:StopQueryExecution",
        ]
        Resource = "arn:aws:athena:${var.aws_deploy_region}:${var.aws_deploy_account_id}:workgroup/primary"
      },
      {
        Sid    = "ReadMosaicAndReferenceCatalogs"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition",
        ]
        Resource = [
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:catalog",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/mosaic_raw",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/mosaic_raw/*",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/mosaic_refined",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/mosaic_refined/*",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/child-fam-services-raw-zone",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/child-fam-services-raw-zone/*",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/child-fam-services-refined-zone",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/child-fam-services-refined-zone/*",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/unrestricted-raw-zone",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/unrestricted-raw-zone/*",
        ]
      },
      {
        Sid    = "ManageMosaicRefinedCatalog"
        Effect = "Allow"
        Action = ["glue:CreateTable", "glue:DeleteTable"]
        Resource = [
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:catalog",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/mosaic_refined",
          "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/mosaic_refined/*",
        ]
      },
      {
        Sid      = "UseLakeFormationGrants"
        Effect   = "Allow"
        Action   = "lakeformation:GetDataAccess"
        Resource = "*"
      },
      {
        Sid    = "ReadMosaicAndReferenceData"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = [
          "${module.raw_zone_data_source.bucket_arn}/projects/mosaic/*",
          "${module.raw_zone_data_source.bucket_arn}/child-fam-services/*",
          "${module.raw_zone_data_source.bucket_arn}/unrestricted/*",
          "${module.refined_zone_data_source.bucket_arn}/child-fam-services/*",
          "${module.athena_storage_data_source.bucket_arn}/child-fam-services/*",
        ]
      },
      {
        Sid    = "WriteMosaicRefinedAndQueryResults"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
        ]
        Resource = [
          "${module.refined_zone_data_source.bucket_arn}/projects/mosaic/*",
          "${module.athena_storage_data_source.bucket_arn}/projects/mosaic/*",
        ]
      },
      {
        Sid    = "GetMosaicBucketDetails"
        Effect = "Allow"
        Action = ["s3:GetBucketLocation", "s3:ListBucketMultipartUploads"]
        Resource = [
          module.raw_zone_data_source.bucket_arn,
          module.refined_zone_data_source.bucket_arn,
          module.athena_storage_data_source.bucket_arn,
        ]
      },
      {
        Sid      = "ListMosaicAndReferenceRawData"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = module.raw_zone_data_source.bucket_arn
        Condition = {
          StringLike = { "s3:prefix" = ["projects/mosaic/*", "child-fam-services/*", "unrestricted/*"] }
        }
      },
      {
        Sid      = "ListMosaicAndReferenceRefinedData"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = module.refined_zone_data_source.bucket_arn
        Condition = {
          StringLike = { "s3:prefix" = ["projects/mosaic/*", "child-fam-services/*"] }
        }
      },
      {
        Sid      = "ListMosaicQueryResultsAndReferenceData"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = module.athena_storage_data_source.bucket_arn
        Condition = {
          StringLike = { "s3:prefix" = ["projects/mosaic/*", "child-fam-services/*"] }
        }
      },
      {
        Sid      = "DecryptMosaicAndReferenceRawData"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = module.raw_zone_data_source.kms_key_arn
      },
      {
        Sid    = "EncryptMosaicRefinedAndQueryResults"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = [
          module.refined_zone_data_source.kms_key_arn,
          module.athena_storage_data_source.kms_key_arn,
        ]
      },
    ]
  })
}

# Allow the CFS ECS task role to build its refined products from Mosaic raw data.
resource "aws_iam_role_policy" "cfs_mosaic_transformations" {
  name = "${local.identifier_prefix}-cfs-mosaic-transformations"
  role = "${local.identifier_prefix}-child-fam-services-ecs-task-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadMosaicRawData"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${module.raw_zone_data_source.bucket_arn}/projects/mosaic/*"
      },
      {
        Sid      = "ReadCfsMosaicSql"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${local.identifier_prefix}-mwaa-bucket/dags/child_fam_services/refined_zone_transformation_dag/*"
      },
    ]
  })
}
