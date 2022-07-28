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
      "kms:*"
    ]
    resources = [
      module.raw_zone.kms_key_arn,
      module.refined_zone.kms_key_arn,
      module.trusted_zone.kms_key_arn,
      "arn:aws:kms:eu-west-2:120038763019:key/03a1da8d-955d-422d-ac0f-fd27946260c0",
      "arn:aws:kms:eu-west-2:120038763019:key/670ec494-c7a3-48d8-ae21-2ef85f2c6d21",
      "arn:aws:kms:eu-west-2:120038763019:key/49166434-f10b-483c-81e4-91f099e4a8a0"
    ]
  }

  statement {
    effect = "Deny"
    actions = [
      "kms:DeleteCustomKeyStore",
      "kms:ScheduleKeyDeletion",
      "kms:DeleteImportedKeyMaterial",
      "kms:DisableKey"
    ]
    resources = [
      module.raw_zone.kms_key_arn,
      module.refined_zone.kms_key_arn,
      module.trusted_zone.kms_key_arn,
      "arn:aws:kms:eu-west-2:120038763019:key/03a1da8d-955d-422d-ac0f-fd27946260c0",
      "arn:aws:kms:eu-west-2:120038763019:key/670ec494-c7a3-48d8-ae21-2ef85f2c6d21",
      "arn:aws:kms:eu-west-2:120038763019:key/49166434-f10b-483c-81e4-91f099e4a8a0"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject*",
      "s3:DeleteObject*"
    ]
    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone*",
      "arn:aws:s3:::dataplatform-stg-refined-zone*",
      "arn:aws:s3:::dataplatform-stg-trusted-zone*"
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
      task_cpu    = 2048
      task_memory = 4096
      environment_variables = [
        { name = "NUMBER_OF_DAYS_TO_RETAIN", value = "90" },
        { name = "S3_SYNC_SOURCE", value = module.raw_zone.bucket_id },
        { name = "S3_SYNC_TARGET", value = "dataplatform-stg-raw-zone" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 22 ? * * *)"
    },
    {
      task_prefix = "refined-zone-"
      task_cpu    = 256
      task_memory = 512
      environment_variables = [
        { name = "NUMBER_OF_DAYS_TO_RETAIN", value = "90" },
        { name = "S3_SYNC_SOURCE", value = module.refined_zone.bucket_id },
        { name = "S3_SYNC_TARGET", value = "dataplatform-stg-refined-zone" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 22 ? * * *)"
    },
    {
      task_prefix = "trusted-zone-"
      task_cpu    = 256
      task_memory = 512
      environment_variables = [
        { name = "NUMBER_OF_DAYS_TO_RETAIN", value = "90" },
        { name = "S3_SYNC_SOURCE", value = module.trusted_zone.bucket_id },
        { name = "S3_SYNC_TARGET", value = "dataplatform-stg-trusted-zone" }
      ]
      cloudwatch_rule_schedule_expression = "cron(0 22 ? * * *)"
    }
  ]
}

resource "aws_s3_bucket_replication_configuration" "raw_zone" {
  count  = local.is_production_environment ? 1 : 0
  role   = var.sync_production_to_pre_production_task_role
  bucket = module.raw_zone.bucket_id

  rule {
    id     = "Production to pre-production raw zone replication"
    status = "Enabled"

    destination {
      bucket  = "arn:aws:s3:::dataplatform-stg-raw-zone"
      account = "120038763019"
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:120038763019:key/03a1da8d-955d-422d-ac0f-fd27946260c0"
      }
    }
  }
}
resource "aws_s3_bucket_replication_configuration" "refined_zone" {
  count  = local.is_production_environment ? 1 : 0
  role   = var.sync_production_to_pre_production_task_role
  bucket = module.refined_zone.bucket_id

  rule {
    id     = "Production to pre-production refined zone replication"
    status = "Enabled"

    destination {
      bucket  = "arn:aws:s3:::dataplatform-stg-refined-zone"
      account = "120038763019"
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:120038763019:key/670ec494-c7a3-48d8-ae21-2ef85f2c6d21"
      }
    }
  }
}
resource "aws_s3_bucket_replication_configuration" "trusted_zone" {
  count  = local.is_production_environment ? 1 : 0
  role   = var.sync_production_to_pre_production_task_role
  bucket = module.trusted_zone.bucket_id

  rule {
    id     = "Production to pre-production trusted zone replication"
    status = "Enabled"

    destination {
      bucket  = "arn:aws:s3:::dataplatform-stg-trusted-zone"
      account = "120038763019"
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:120038763019:key/49166434-f10b-483c-81e4-91f099e4a8a0"
      }
    }
  }
}
