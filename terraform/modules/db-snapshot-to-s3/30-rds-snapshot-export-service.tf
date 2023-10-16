data "aws_iam_policy_document" "rds_snapshot_export_service_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "export.rds.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "rds_snapshot_export_service" {

  tags = var.tags

  name               = lower("${var.identifier_prefix}-rds-snapshot-export-service")
  assume_role_policy = data.aws_iam_policy_document.rds_snapshot_export_service_assume_role.json
}

data "aws_iam_policy_document" "rds_snapshot_export_service" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject*",
      "s3:GetObject*",
      "s3:CopyObject*",
      "s3:DeleteObject*"
    ]
    resources = [
      var.rds_export_storage_bucket_arn,
      "${var.rds_export_storage_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    resources = [
      var.rds_export_storage_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "rds_snapshot_export_service" {

  tags = var.tags

  name        = lower("${var.identifier_prefix}-rds-snapshot-export-service")
  description = "A policy that allows the RDS Snapshot Service to write to the Data Platform S3 Landing Zone"
  policy      = data.aws_iam_policy_document.rds_snapshot_export_service.json
}

resource "aws_iam_role_policy_attachment" "rds_snapshot_export_service" {
  role       = aws_iam_role.rds_snapshot_export_service.name
  policy_arn = aws_iam_policy.rds_snapshot_export_service.arn
}
