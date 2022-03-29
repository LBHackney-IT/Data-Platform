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
      "s3:ListBucket",
    ]
    resources = [
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/*",
      module.refined_zone.bucket_arn,
      "${module.refined_zone.bucket_arn}/*",
      module.trusted_zone.bucket_arn,
      "${module.trusted_zone.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      module.raw_zone.kms_key_arn,
      module.refined_zone.kms_key_arn,
      module.trusted_zone.kms_key_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone-prod-copy*",
      "arn:aws:s3:::dataplatform-stg-refined-zone-copy*",
      "arn:aws:s3:::dataplatform-stg-trusted-zone-prod-copy*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [
      "arn:aws:kms:eu-west-2:120038763019:key/03a1da8d-955d-422d-ac0f-fd27946260c0",
      "arn:aws:kms:eu-west-2:120038763019:key/670ec494-c7a3-48d8-ae21-2ef85f2c6d21",
      "arn:aws:kms:eu-west-2:120038763019:key/49166434-f10b-483c-81e4-91f099e4a8a0"
    ]
  }
}

module "sync_production_to_pre_production" {
  source = "../modules/aws-ecs-fargate-task"
  count  = local.is_production_environment ? 1 : 0

  tags                          = module.tags.values
  operation_name                = "${local.short_identifier_prefix}sync-production-to-pre-production"
  ecs_task_role_policy_document = data.aws_iam_policy_document.task_role.json
  aws_subnet_ids                = data.aws_subnet_ids.network.ids
  ecs_cluster_arn               = aws_ecs_cluster.workers.arn
  tasks = [
    {
      task_prefix = "raw-zone-"
      environment_variables = [
        { "name" = "NUMBER_OF_DAYS_TO_RETAIN", "value" = "90" },
        { "name" = "S3_SYNC_SOURCE", "value" = module.raw_zone.bucket_id },
        { "name" = "S3_SYNC_TARGET", "value" = "dataplatform-stg-raw-zone-prod-copy" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 23 ? * * *)"
    },
    {
      task_prefix = "refined-zone-"
      environment_variables = [
        { "name" = "NUMBER_OF_DAYS_TO_RETAIN", "value" = "90" },
        { "name" = "S3_SYNC_SOURCE", "value" = module.refined_zone.bucket_id },
        { "name" = "S3_SYNC_TARGET", "value" = "dataplatform-stg-refined-zone-prod-copy" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 23 ? * * *)"
    },
    {
      task_prefix = "trusted-zone-"
      environment_variables = [
        { "name" = "NUMBER_OF_DAYS_TO_RETAIN", "value" = "90" },
        { "name" = "S3_SYNC_SOURCE", "value" = module.trusted_zone.bucket_id },
        { "name" = "S3_SYNC_TARGET", "value" = "dataplatform-stg-trusted-zone-prod-copy" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 23 ? * * *)"
    }
  ]
}
