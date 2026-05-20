# Staging-side access for the dap-airflow dev branch S3 replication path.
#
# Intended flow:
# - Engineers push directly to the `dev` branch in the LBHackney-IT/dap-airflow repository.
# - The dap-airflow GitHub Action assumes the dev account `LBH_Automation_Deployment_Role`.
# - The workflow syncs files into manually-created dev buckets:
#   - dataplatform-dev-mwaa-bucket
#   - dataplatform-dev-mwaa-etl-scripts-bucket
# - S3 replication on those dev buckets then copies the objects into the staging MWAA buckets:
#   - dataplatform-stg-mwaa-bucket
#   - dataplatform-stg-mwaa-etl-scripts-bucket
#
# Dev-account resources are intentionally not created in this file. They are created manually in
# account 484466746276 and should include:
# - source bucket: dataplatform-dev-mwaa-bucket
# - source bucket: dataplatform-dev-mwaa-etl-scripts-bucket
# - replication role: dap-airflow-dev-to-stg-mwaa-replication-role
# - replication configuration on each dev bucket targeting the matching staging bucket
#
# This file only owns the staging destination side:
# - versioning on the staging MWAA buckets, required for S3 replication
# - noncurrent-version lifecycle cleanup on the staging MWAA buckets
# - staging bucket policies that allow the dev replication role to write replicas
# - the local values used by 46-mwaa-bucket-kms.tf to allow the dev replication role to
#   encrypt replicas with the staging MWAA KMS key


locals {
  dap_airflow_dev_account_id                          = "484466746276"
  dap_airflow_dev_to_stg_mwaa_replication_role_name   = "dap-airflow-dev-to-stg-mwaa-replication-role"
  dap_airflow_dev_to_stg_mwaa_replication_role_arn    = "arn:aws:iam::${local.dap_airflow_dev_account_id}:role/${local.dap_airflow_dev_to_stg_mwaa_replication_role_name}"
  dap_airflow_mwaa_noncurrent_version_expiration_days = 30
  dap_airflow_dev_to_stg_mwaa_replication_s3_actions  = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags", "s3:ObjectOwnerOverrideToBucketOwner"]
  dap_airflow_dev_to_stg_mwaa_replication_kms_actions = ["kms:Encrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
  dap_airflow_dev_to_stg_mwaa_replication_kms_policy_statement = {
    Sid    = "AllowDevDapAirflowReplicationToUseMwaaKey"
    Effect = "Allow"
    Principal = {
      AWS = local.dap_airflow_dev_to_stg_mwaa_replication_role_arn
    }
    Action   = local.dap_airflow_dev_to_stg_mwaa_replication_kms_actions
    Resource = "*"
  }

  dap_airflow_stg_mwaa_replication_destinations = {
    dags = {
      bucket_id  = aws_s3_bucket.mwaa_bucket.id
      bucket_arn = aws_s3_bucket.mwaa_bucket.arn
      sid_name   = "MwaaBucket"
    }
    etl_scripts = {
      bucket_id  = aws_s3_bucket.mwaa_etl_scripts_bucket.id
      bucket_arn = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
      sid_name   = "MwaaEtlScriptsBucket"
    }
  }
}

resource "aws_s3_bucket_versioning" "mwaa_replication_destinations" {
  for_each = local.environment == "stg" ? local.dap_airflow_stg_mwaa_replication_destinations : {}

  bucket = each.value.bucket_id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mwaa_replication_destinations" {
  for_each = local.environment == "stg" ? local.dap_airflow_stg_mwaa_replication_destinations : {}

  bucket = each.value.bucket_id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = local.dap_airflow_mwaa_noncurrent_version_expiration_days
    }
  }
}

data "aws_iam_policy_document" "mwaa_dev_replication" {
  for_each = local.environment == "stg" ? local.dap_airflow_stg_mwaa_replication_destinations : {}

  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      each.value.bucket_arn,
      "${each.value.bucket_arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowDevDapAirflowReplicationTo${each.value.sid_name}"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]

    principals {
      type        = "AWS"
      identifiers = [local.dap_airflow_dev_to_stg_mwaa_replication_role_arn]
    }

    resources = [each.value.bucket_arn]
  }

  statement {
    sid     = "AllowDevDapAirflowReplicationTo${each.value.sid_name}Objects"
    effect  = "Allow"
    actions = local.dap_airflow_dev_to_stg_mwaa_replication_s3_actions

    principals {
      type        = "AWS"
      identifiers = [local.dap_airflow_dev_to_stg_mwaa_replication_role_arn]
    }

    resources = ["${each.value.bucket_arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "mwaa_dev_replication" {
  for_each = local.environment == "stg" ? local.dap_airflow_stg_mwaa_replication_destinations : {}

  bucket = each.value.bucket_id
  policy = data.aws_iam_policy_document.mwaa_dev_replication[each.key].json

  depends_on = [
    aws_s3_bucket_public_access_block.mwaa_bucket_block,
    aws_s3_bucket_public_access_block.mwaa_etl_scripts_bucket_block
  ]
}
