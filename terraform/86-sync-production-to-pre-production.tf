locals {
  environment_variables = [
    { "name" : "NUMBER_OF_DAYS_TO_RETAIN", "value" : "7" },
    { "name" = "S3_SYNC_SOURCE", "value" = module.raw_zone.bucket_id },
    { "name" = "S3_SYNC_TARGET", "value" = "dataplatform-stg-raw-zone-prod-copy" }
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
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone-prod-copy*"
    ]
  }
}

module "sync_production_to_pre_production" {
  source = "../modules/aws-ecs-fargate-task"
  count  = local.is_production_environment ? 1 : 0

  tags                                = module.tags.values
  operation_name                      = "${local.short_identifier_prefix}sync-production-to-pre-production"
  environment_variables               = local.environment_variables
  ecs_task_role_policy_document       = data.aws_iam_policy_document.task_role.json
  aws_subnet_ids                      = data.aws_subnet_ids.network.ids
  cloudwatch_rule_schedule_expression = "cron(15 06 ? * MON-FRI *)"
  ecs_cluster_arn                     = aws_ecs_cluster.workers.arn
}
