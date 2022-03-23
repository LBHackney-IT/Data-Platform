locals {
  environment_variables = [
    { "name" : "NUMBER_OF_DAYS_TO_RETAIN", "value" : "90" },
    { "name" = "S3_SYNC_SOURCE", "value" = module.raw_zone.bucket_id },
    { "name" = "S3_SYNC_TARGET", "value" = "lbh-academy-dev-emma-file-sync" }
  ]
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "task_role" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:ListBucket"
    ]
    resources = [
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/*",
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:*"
    ]
    resources = [module.raw_zone.kms_key_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject*",
      "s3:CompleteMultipartUpload"
    ]
    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone-prod-copy*",
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:*"
    ]
    resources = ["arn:aws:kms:eu-west-2:937934410339:key/e12cee2b-2c2a-4715-9ae7-fff703a7caa0"]
  }
}

module "sync_production_to_pre_production" {
  source = "../modules/aws-ecs-fargate-task"
  count  = true ? 1 : 0

  tags                          = module.tags.values
  operation_name                = "${local.short_identifier_prefix}sync-production-to-pre-production"
  environment_variables         = local.environment_variables
  ecs_task_role_policy_document = data.aws_iam_policy_document.task_role.json
  aws_subnet_ids                = data.aws_subnet_ids.network.ids
  task_schedule                 = "cron(40 15 ? * TUE *)"
}
