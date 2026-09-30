/*
Additional Needs ML access workflow

Job orchestration in staging

  housing-airflow-role
    -> starts and monitors a SageMaker Processing job
    -> passes housing-additional-needs-sagemaker-execution-role to SageMaker

  SageMaker Processing job
    -> pulls the processing image from housing-additional-needs-ml ECR
    -> reads and writes code, artefacts, and outputs in the encrypted ML bucket

Production data access through Athena

  DataPlatformHousingStg users or the SageMaker execution role
    -> use the existing housing Athena workgroup
    -> use the prod__housing-raw-zone and prod__housing-refined-zone Glue links
    -> receive Lake Formation access to the shared production catalog
    -> query only:
       - housing-raw-zone.mtfh_notes
       - housing-raw-zone.mtfh_tenureinformation
       - housing-refined-zone.additional_needs_notes_reshaped

  Query results
    -> default to s3://dataplatform-stg-athena-storage/housing/
    -> may be directed to any prefix in the Additional Needs ML bucket

Production data access through the S3 SDK

  SageMaker execution role
    -> assumes dataplatform-prod-housing-additional-needs-data-reader-role
    -> reads only the three approved production S3 prefixes and KMS keys

Access boundaries

  - Housing SSO users remain in staging and have no direct production S3 access.
  - dap-infrastructure owns the cross-account database shares and Glue links.
  - Additional Needs trusted-zone data exists only in staging; no production
    trusted-zone resource is shared.
  - Project-specific access resources are kept in this file for later removal.
*/

locals {
  housing_additional_needs_ml_staging    = local.is_live_environment && local.environment == "stg"
  housing_additional_needs_ml_production = local.is_live_environment && local.environment == "prod"

  housing_additional_needs_staging_account_id         = "120038763019"
  housing_additional_needs_staging_sagemaker_role_arn = "arn:aws:iam::${local.housing_additional_needs_staging_account_id}:role/housing-additional-needs-sagemaker-execution-role"

  # dap-infrastructure creates these resource links in staging. This map links
  # each existing local name to its target database in the production catalog.
  housing_additional_needs_existing_production_resource_links = {
    "prod__housing-raw-zone"     = "housing-raw-zone"
    "prod__housing-refined-zone" = "housing-refined-zone"
  }

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
    sid = "ListMLStorage"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
    resources = [module.housing_additional_needs_ml_storage[0].bucket_arn]
  }

  statement {
    sid = "ReadWriteMLStorage"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${module.housing_additional_needs_ml_storage[0].bucket_arn}/*"]
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
    sid       = "AssumeProductionDataReader"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:role/dataplatform-prod-housing-additional-needs-data-reader-role"]
  }

  statement {
    sid = "ReadSharedProductionCatalog"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
    ]
    resources = concat(
      [
        "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:catalog",
        "arn:aws:glue:${var.aws_deploy_region}:${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:catalog",
      ],
      [for database in keys(local.housing_additional_needs_existing_production_resource_links) : "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/${database}"],
      [for database in keys(local.housing_additional_needs_existing_production_resource_links) : "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/${database}/*"],
      [for database in values(local.housing_additional_needs_existing_production_resource_links) : "arn:aws:glue:${var.aws_deploy_region}:${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:database/${database}"],
      [for source in values(local.housing_additional_needs_ml_source_tables) : "arn:aws:glue:${var.aws_deploy_region}:${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:table/${source.database}/${source.table}"],
    )
  }

  statement {
    sid       = "LakeFormationDataAccess"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }

  statement {
    sid = "QuerySharedProductionTables"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryRuntimeStatistics",
      "athena:GetWorkGroup",
      "athena:StopQueryExecution",
    ]
    resources = ["arn:aws:athena:${var.aws_deploy_region}:${var.aws_deploy_account_id}:workgroup/housing"]
  }

  statement {
    sid       = "LocateHousingAthenaResults"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.athena_storage.bucket_arn]
  }

  statement {
    sid = "ListHousingAthenaResults"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
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
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${module.athena_storage.bucket_arn}/housing/*"]
  }

  statement {
    sid = "HousingAthenaResultsKey"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [module.athena_storage.kms_key_arn]
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

data "aws_iam_policy_document" "housing_additional_needs_staging_sso" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  statement {
    sid = "ReadSharedProductionCatalog"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
    ]
    resources = concat(
      [
        "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:catalog",
        "arn:aws:glue:${var.aws_deploy_region}:${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:catalog",
      ],
      [for database in keys(local.housing_additional_needs_existing_production_resource_links) : "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/${database}"],
      [for database in keys(local.housing_additional_needs_existing_production_resource_links) : "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/${database}/*"],
      [for database in values(local.housing_additional_needs_existing_production_resource_links) : "arn:aws:glue:${var.aws_deploy_region}:${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:database/${database}"],
      [for source in values(local.housing_additional_needs_ml_source_tables) : "arn:aws:glue:${var.aws_deploy_region}:${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:table/${source.database}/${source.table}"],
    )
  }

  statement {
    sid       = "LakeFormationDataAccess"
    actions   = ["lakeformation:GetDataAccess"]
    resources = ["*"]
  }

  statement {
    sid = "ListMLStorage"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads",
    ]
    resources = [module.housing_additional_needs_ml_storage[0].bucket_arn]
  }

  statement {
    sid = "ManageMLStorageObjects"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["${module.housing_additional_needs_ml_storage[0].bucket_arn}/*"]
  }

  statement {
    sid = "UseMLStorageKey"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [module.housing_additional_needs_ml_storage[0].kms_key_arn]
  }
}

resource "aws_iam_policy" "housing_additional_needs_staging_sso" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  name   = "dataplatform-stg-housing-additional-needs-production-data-read"
  policy = data.aws_iam_policy_document.housing_additional_needs_staging_sso[0].json
  tags   = module.tags.values
}

data "aws_ssoadmin_permission_set" "housing_staging" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  provider     = aws.aws_hackit_account
  instance_arn = local.sso_instance_arn
  name         = "DataPlatformHousingStg"
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "housing_additional_needs_staging_sso" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  provider = aws.aws_hackit_account

  instance_arn       = local.sso_instance_arn
  permission_set_arn = data.aws_ssoadmin_permission_set.housing_staging[0].arn

  customer_managed_policy_reference {
    name = aws_iam_policy.housing_additional_needs_staging_sso[0].name
    path = "/"
  }

  depends_on = [module.department_housing]
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

data "aws_iam_policy_document" "housing_additional_needs_production_data_reader_assume" {
  count = local.housing_additional_needs_ml_production ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.housing_additional_needs_staging_account_id}:root"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:PrincipalArn"
      values   = [local.housing_additional_needs_staging_sagemaker_role_arn]
    }
  }
}

resource "aws_iam_role" "housing_additional_needs_production_data_reader" {
  count = local.housing_additional_needs_ml_production ? 1 : 0

  name               = "dataplatform-prod-housing-additional-needs-data-reader-role"
  description        = "Allows the staging Additional Needs SageMaker job to read the three approved production data prefixes"
  assume_role_policy = data.aws_iam_policy_document.housing_additional_needs_production_data_reader_assume[0].json
  tags               = module.tags.values
}

data "aws_iam_policy_document" "housing_additional_needs_production_data_reader" {
  count = local.housing_additional_needs_ml_production ? 1 : 0

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
        "housing/mtfh/mtfh_tenureinformation/*",
      ]
    }
  }

  statement {
    sid     = "ReadRawSourceTables"
    actions = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = [
      "${module.raw_zone.bucket_arn}/housing/mtfh/mtfh_notes/*",
      "${module.raw_zone.bucket_arn}/housing/mtfh/mtfh_tenureinformation/*",
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
        "housing/additional_needs/additional_needs_notes_reshaped/*",
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
}

resource "aws_iam_role_policy" "housing_additional_needs_production_data_reader" {
  count = local.housing_additional_needs_ml_production ? 1 : 0

  name   = "housing-additional-needs-production-data-read"
  role   = aws_iam_role.housing_additional_needs_production_data_reader[0].id
  policy = data.aws_iam_policy_document.housing_additional_needs_production_data_reader[0].json
}

data "aws_iam_roles" "housing_additional_needs_staging_sso" {
  count = local.housing_additional_needs_ml_staging ? 1 : 0

  name_regex  = "^AWSReservedSSO_DataPlatformHousingStg_.*$"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  housing_additional_needs_staging_principals = local.housing_additional_needs_ml_staging ? {
    sagemaker_execution = aws_iam_role.housing_additional_needs_sagemaker_execution[0].arn
    housing_sso         = one(data.aws_iam_roles.housing_additional_needs_staging_sso[0].arns)
  } : {}

  housing_additional_needs_staging_database_grants = merge([
    for principal_name, principal_arn in local.housing_additional_needs_staging_principals : {
      for link_name, source_database in local.housing_additional_needs_existing_production_resource_links :
      "${principal_name}-${link_name}" => {
        link_name       = link_name
        source_database = source_database
        principal_arn   = principal_arn
      }
    }
  ]...)

  housing_additional_needs_staging_table_grants = merge([
    for principal_name, principal_arn in local.housing_additional_needs_staging_principals : {
      for table_name, source in local.housing_additional_needs_ml_source_tables :
      "${principal_name}-${table_name}" => {
        database      = source.database
        table         = source.table
        principal_arn = principal_arn
      }
    }
  ]...)
}

resource "aws_lakeformation_permissions" "housing_additional_needs_staging_shared_database" {
  for_each = local.housing_additional_needs_staging_database_grants

  principal   = each.value.principal_arn
  permissions = ["DESCRIBE"]

  database {
    catalog_id = data.aws_secretsmanager_secret_version.production_account_id.secret_string
    name       = each.value.source_database
  }
}

resource "aws_lakeformation_permissions" "housing_additional_needs_staging_shared_table" {
  for_each = local.housing_additional_needs_staging_table_grants

  principal   = each.value.principal_arn
  permissions = ["DESCRIBE", "SELECT"]

  table {
    catalog_id    = data.aws_secretsmanager_secret_version.production_account_id.secret_string
    database_name = each.value.database
    name          = each.value.table
  }

  depends_on = [aws_lakeformation_permissions.housing_additional_needs_staging_shared_database]
}

resource "aws_lakeformation_permissions" "housing_additional_needs_staging_resource_link" {
  for_each = local.housing_additional_needs_staging_database_grants

  principal   = each.value.principal_arn
  permissions = ["DESCRIBE"]

  database {
    name = each.value.link_name
  }

  lifecycle {
    ignore_changes = [permissions]
  }
}

resource "aws_lakeformation_opt_in" "housing_additional_needs_staging_shared_database" {
  for_each = local.housing_additional_needs_staging_database_grants

  principal {
    data_lake_principal_identifier = each.value.principal_arn
  }

  resource_data {
    database {
      catalog_id = data.aws_secretsmanager_secret_version.production_account_id.secret_string
      name       = each.value.source_database
    }
  }

  depends_on = [aws_lakeformation_permissions.housing_additional_needs_staging_shared_database]
}

resource "aws_lakeformation_opt_in" "housing_additional_needs_staging_shared_table" {
  for_each = local.housing_additional_needs_staging_table_grants

  principal {
    data_lake_principal_identifier = each.value.principal_arn
  }

  resource_data {
    table {
      catalog_id    = data.aws_secretsmanager_secret_version.production_account_id.secret_string
      database_name = each.value.database
      name          = each.value.table
    }
  }

  depends_on = [
    aws_lakeformation_permissions.housing_additional_needs_staging_shared_table,
    aws_lakeformation_opt_in.housing_additional_needs_staging_shared_database,
  ]
}
