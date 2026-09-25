/*
Additional Needs ML infrastructure.

In staging, this creates the ECR repository and SageMaker execution role used
to run Additional Needs processing jobs, and grants the existing Housing
Airflow role permission to start and monitor those jobs and pass the execution
role to SageMaker. The encrypted, versioned ML storage bucket is declared in
10-aws-s3-special-buckets.tf.

In production, this creates a standalone ECS task role with scoped Glue,
Athena, S3, KMS, and Lake Formation permissions to read the three source tables
required by the Additional Needs workload. Existing Housing ECS task
definitions remain unchanged.
*/

locals {
  housing_additional_needs_ml_staging    = local.is_live_environment && local.environment == "stg"
  housing_additional_needs_ml_production = local.is_live_environment && local.environment == "prod"

  housing_additional_needs_ml_source_tables = {
    mtfh_notes = {
      database = "housing-raw-zone"
      table    = "mtfh_notes"
    }
    mtfh_tenureinformation = {
      database = "housing-raw-zone"
      table    = "mtfh_tenureinformation"
    }
    additional_needs_notes_reshaped = {
      database = "housing-refined-zone"
      table    = "additional_needs_notes_reshaped"
    }
  }
}

resource "aws_ecr_repository" "housing_additional_needs_ml" {
  count                = local.housing_additional_needs_ml_staging ? 1 : 0
  name                 = "housing-additional-needs-ml"
  image_tag_mutability = "IMMUTABLE"
  tags                 = module.tags.values

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_policy_document" "housing_additional_needs_sagemaker_assume" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "housing_additional_needs_sagemaker_execution" {
  count              = local.housing_additional_needs_ml_staging ? 1 : 0
  name               = "housing-additional-needs-sagemaker-execution-role"
  assume_role_policy = data.aws_iam_policy_document.housing_additional_needs_sagemaker_assume[0].json
  tags               = module.tags.values
}

data "aws_iam_policy_document" "housing_additional_needs_sagemaker_execution" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  statement {
    sid       = "ListMLStorage"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [module.housing_additional_needs_ml_storage[0].bucket_arn]
  }

  statement {
    sid       = "ReadWriteMLStorage"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["${module.housing_additional_needs_ml_storage[0].bucket_arn}/*"]
  }

  statement {
    sid       = "LocateRefinedNotes"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.refined_zone.bucket_arn]
  }

  statement {
    sid       = "ListRefinedNotes"
    actions   = ["s3:ListBucket"]
    resources = [module.refined_zone.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "housing/additional_needs/additional_needs_notes_reshaped",
        "housing/additional_needs/additional_needs_notes_reshaped/*"
      ]
    }
  }

  statement {
    sid       = "ReadRefinedNotes"
    actions   = ["s3:GetObject"]
    resources = ["${module.refined_zone.bucket_arn}/housing/additional_needs/additional_needs_notes_reshaped/*"]
  }

  statement {
    sid = "MLStorageKey"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [module.housing_additional_needs_ml_storage[0].kms_key_arn]
  }

  statement {
    sid       = "RefinedZoneKey"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [module.refined_zone.kms_key_arn]
  }

  statement {
    sid       = "ECRAuthorization"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullInferenceImage"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [aws_ecr_repository.housing_additional_needs_ml[0].arn]
  }

  statement {
    sid = "ProcessingLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_deploy_region}:${var.aws_deploy_account_id}:log-group:/aws/sagemaker/ProcessingJobs",
      "arn:aws:logs:${var.aws_deploy_region}:${var.aws_deploy_account_id}:log-group:/aws/sagemaker/ProcessingJobs:*"
    ]
  }

  statement {
    sid       = "ProcessingMetrics"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "housing_additional_needs_sagemaker_execution" {
  count  = local.housing_additional_needs_ml_staging ? 1 : 0
  name   = "housing-additional-needs-sagemaker-execution"
  role   = aws_iam_role.housing_additional_needs_sagemaker_execution[0].id
  policy = data.aws_iam_policy_document.housing_additional_needs_sagemaker_execution[0].json
}

data "aws_iam_policy_document" "housing_additional_needs_airflow" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  statement {
    sid = "RunAdditionalNeedsProcessing"
    actions = [
      "sagemaker:CreateProcessingJob",
      "sagemaker:DescribeProcessingJob"
    ]
    resources = [
      "arn:aws:sagemaker:${var.aws_deploy_region}:${var.aws_deploy_account_id}:processing-job/housing-additional-needs-*"
    ]
  }

  statement {
    sid       = "ListProcessingJobs"
    actions   = ["sagemaker:ListProcessingJobs"]
    resources = ["*"]
  }

  statement {
    sid       = "PassAdditionalNeedsExecutionRole"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.housing_additional_needs_sagemaker_execution[0].arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "housing_additional_needs_airflow" {
  count      = local.housing_additional_needs_ml_staging ? 1 : 0
  name       = "housing-additional-needs-sagemaker-processing"
  role       = "housing-airflow-role"
  policy     = data.aws_iam_policy_document.housing_additional_needs_airflow[0].json
  depends_on = [module.department_housing]
}

data "aws_iam_policy_document" "housing_additional_needs_ecs_assume" {
  count = local.housing_additional_needs_ml_production ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "housing_additional_needs_ecs_task" {
  count              = local.housing_additional_needs_ml_production ? 1 : 0
  name               = "dataplatform-prod-housing-additional-needs-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.housing_additional_needs_ecs_assume[0].json
  tags               = module.tags.values
}

data "aws_iam_policy_document" "housing_additional_needs_ecs_task" {
  count = local.housing_additional_needs_ml_production ? 1 : 0

  statement {
    sid = "ReadHousingCatalog"
    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"
    ]
    resources = concat(
      ["arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:catalog"],
      [for database in toset(["housing-raw-zone", "housing-refined-zone"]) : "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/${database}"],
      [for source in values(local.housing_additional_needs_ml_source_tables) : "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/${source.database}/${source.table}"]
    )
  }

  statement {
    sid       = "LakeFormationDataAccess"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }

  statement {
    sid = "ReadHousingWithAthena"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:StopQueryExecution"
    ]
    resources = ["arn:aws:athena:${var.aws_deploy_region}:${var.aws_deploy_account_id}:workgroup/housing"]
  }

  statement {
    sid       = "LocateSourceBuckets"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.raw_zone.bucket_arn, module.refined_zone.bucket_arn]
  }

  statement {
    sid       = "ListRawSourceTables"
    actions   = ["s3:ListBucket"]
    resources = [module.raw_zone.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "housing/mtfh/mtfh_notes",
        "housing/mtfh/mtfh_notes/*",
        "housing/mtfh/mtfh_tenureinformation",
        "housing/mtfh/mtfh_tenureinformation/*"
      ]
    }
  }

  statement {
    sid     = "ReadRawSourceTables"
    actions = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = [
      "${module.raw_zone.bucket_arn}/housing/mtfh/mtfh_notes/*",
      "${module.raw_zone.bucket_arn}/housing/mtfh/mtfh_tenureinformation/*"
    ]
  }

  statement {
    sid       = "ListRefinedSourceTable"
    actions   = ["s3:ListBucket"]
    resources = [module.refined_zone.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "housing/additional_needs/additional_needs_notes_reshaped",
        "housing/additional_needs/additional_needs_notes_reshaped/*"
      ]
    }
  }

  statement {
    sid       = "ReadRefinedSourceTable"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = ["${module.refined_zone.bucket_arn}/housing/additional_needs/additional_needs_notes_reshaped/*"]
  }

  statement {
    sid       = "DecryptSourceTables"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [module.raw_zone.kms_key_arn, module.refined_zone.kms_key_arn]
  }

  statement {
    sid       = "LocateHousingAthenaResults"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.athena_storage.bucket_arn]
  }

  statement {
    sid       = "ListHousingAthenaResults"
    actions   = ["s3:ListBucket"]
    resources = [module.athena_storage.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["housing", "housing/*"]
    }
  }

  statement {
    sid = "ReadWriteHousingAthenaResults"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]
    resources = ["${module.athena_storage.bucket_arn}/housing/*"]
  }

  statement {
    sid = "HousingAthenaResultsKey"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [module.athena_storage.kms_key_arn]
  }
}

resource "aws_iam_role_policy" "housing_additional_needs_ecs_task" {
  count  = local.housing_additional_needs_ml_production ? 1 : 0
  name   = "housing-additional-needs-data-read"
  role   = aws_iam_role.housing_additional_needs_ecs_task[0].id
  policy = data.aws_iam_policy_document.housing_additional_needs_ecs_task[0].json
}

resource "aws_lakeformation_permissions" "housing_additional_needs_database_describe" {
  for_each = local.housing_additional_needs_ml_production ? toset(["housing-raw-zone", "housing-refined-zone"]) : toset([])

  principal   = aws_iam_role.housing_additional_needs_ecs_task[0].arn
  permissions = ["DESCRIBE"]

  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "housing_additional_needs_table_read" {
  for_each = local.housing_additional_needs_ml_production ? local.housing_additional_needs_ml_source_tables : {}

  principal   = aws_iam_role.housing_additional_needs_ecs_task[0].arn
  permissions = ["DESCRIBE", "SELECT"]
  depends_on  = [aws_lakeformation_permissions.housing_additional_needs_database_describe]

  table {
    database_name = each.value.database
    name          = each.value.table
  }
}
