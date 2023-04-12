data "aws_iam_policy_document" "pre_production_data_cleanup_task_role" {
  count  = !local.is_production_environment && local.is_live_environment ? 1 : 0
  
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
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
      "s3:DeleteObject*"
    ]
    #hard coded to prevent data loss in case of misconfiguration
    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone*",
      "arn:aws:s3:::dataplatform-stg-refined-zone*",
      "arn:aws:s3:::dataplatform-stg-trusted-zone*",
      "arn:aws:s3:::dataplatform-stg-raw-zone/*",
      "arn:aws:s3:::dataplatform-stg-refined-zone/*",
      "arn:aws:s3:::dataplatform-stg-trusted-zone/*"
    ]
  }
}

module "pre_production_data_cleanup" {
  source = "../modules/aws-ecs-fargate-task"
  count  = !local.is_production_environment && local.is_live_environment ? 1 : 0

  tags                          = module.tags.values
  operation_name                = "${local.short_identifier_prefix}pre-production-data-cleanup"
  ecs_task_role_policy_document = data.aws_iam_policy_document.pre_production_data_cleanup_task_role[0].json
  aws_subnet_ids                = data.aws_subnet_ids.network.ids
  ecs_cluster_arn               = aws_ecs_cluster.workers.arn
  tasks = [
    {
      task_prefix = "raw-zone-"
      task_cpu    = 256
      task_memory = 512
      environment_variables = [
        { name = "NUMBER_OF_DAYS_TO_RETAIN", value = "90" },
        { name = "S3_CLEANUP_TARGET", value = "dataplatform-stg-raw-zone" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 0 ? * 1 *)"
    },
    {
      task_prefix = "refined-zone-"
      task_cpu    = 256
      task_memory = 512
      environment_variables = [
        { name = "NUMBER_OF_DAYS_TO_RETAIN", value = "90" },
        { name = "S3_CLEANUP_TARGET", value = "dataplatform-stg-refined-zone" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 0 ? * 1 *)"
    },
    {
      task_prefix = "trusted-zone-"
      task_cpu    = 256
      task_memory = 512
      environment_variables = [
        { name = "NUMBER_OF_DAYS_TO_RETAIN", value = "90" },
        { name = "S3_CLEANUP_TARGET", value = "dataplatform-stg-trusted-zone" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 0 ? * 1 *)"
    }
  ]
  security_groups = [aws_security_group.pre_production_data_cleanup[0].id]
}

resource "aws_security_group" "pre_production_data_cleanup" {
  count       = !local.is_production_environment && local.is_live_environment ? 1 : 0
  name        = "${local.short_identifier_prefix}pre-production-data-cleanup"
  description = "Restrict access for the cleanup task"
  vpc_id      = data.aws_vpc.network.id
  tags        = module.tags.values
}

resource "aws_security_group_rule" "outbound_traffic_to_s3" {
  count             = !local.is_production_environment && local.is_live_environment ? 1 : 0
  description       = "Allow outbound traffic to S3"
  security_group_id = aws_security_group.pre_production_data_cleanup[0].id
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}
