data "aws_caller_identity" "current" {}

module "dynamodb_table" {
  source = "../modules/dynamodb"
  count  = !local.is_live_environment ? 1 : 0

  name                           = "glue-watermarks"
  identifier_prefix              = local.short_identifier_prefix
  billing_mode                   = "PAY_PER_REQUEST"
  hash_key                       = "jobName"
  range_key                      = "runId"
  table_class                    = "STANDARD"
  point_in_time_recovery_enabled = true
  tags                           = merge(module.tags.values, { BackupPolicy = title(var.environment) })

  attributes = [
    {
      name = "jobName"
      type = "S"
    },
    {
      name = "runId"
      type = "S"
    }
  ]

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = aws_kms_key.watermarks_dynamo_db.arn
}

resource "aws_kms_key" "watermarks_dynamo_db" {
  description = "KMS key for watermarks dynamodb"
  policy      = data.aws_iam_policy_document.watermarks_key_policy.json
  tags        = module.tags.values
}

data "aws_iam_policy_document" "watermarks_key_policy" {

  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

