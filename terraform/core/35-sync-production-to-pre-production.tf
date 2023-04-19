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

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "s3.amazonaws.com"
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
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
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
      "s3:DeleteObject*",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete",
    ]
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
      cloudwatch_rule_schedule_expression = "cron(0 0 1 1 ? 2050)"
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
      cloudwatch_rule_schedule_expression = "cron(0 0 1 1 ? 2050)"
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
      cloudwatch_rule_schedule_expression = "cron(0 0 1 1 ? 2050)"
    }
  ]
  security_groups = [aws_security_group.pre_production_clean_up[0].id]
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

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
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

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
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

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}

resource "aws_security_group" "pre_production_clean_up" {
  count       = local.is_production_environment ? 1 : 0
  name        = "${local.short_identifier_prefix}sync-production-to-pre-production"
  description = "Restrict access for the clean up task"
  vpc_id      = data.aws_vpc.network.id
  tags        = module.tags.values
}

resource "aws_security_group_rule" "allow_outbound_traffic_to_s3" {
  count             = local.is_production_environment ? 1 : 0
  description       = "Allow outbound traffic to S3"
  security_group_id = aws_security_group.pre_production_clean_up[0].id
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

data "aws_iam_policy_document" "prod_to_pre_prod_s3_sync_policy" {
  count = local.is_production_environment ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ListBucket"
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
      "kms:RetireGrant",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:CreateGrant"
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
      "s3:DeleteObject*",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete"
    ]
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

data "aws_iam_policy_document" "s3_assume_role" {
  count = local.is_production_environment ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "s3.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "prod_to_pre_prod_s3_sync_role" {
  count = local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  name               = "${local.short_identifier_prefix}production-to-pre-production-s3-sync-role"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role[0].json
}

resource "aws_iam_policy" "prod_to_pre_prod_s3_sync_policy" {
  count  = local.is_production_environment ? 1 : 0
  tags   = module.tags.values
  name   = "${local.short_identifier_prefix}production-to-pre-production-s3-sync"
  policy = data.aws_iam_policy_document.prod_to_pre_prod_s3_sync_policy[0].json
}

resource "aws_iam_policy_attachment" "prod_to_pre_prod_s3_sync_policy_attachment" {
  count      = local.is_production_environment ? 1 : 0
  name       = "${local.short_identifier_prefix}production-to-pre-production-s3-sync"
  roles      = [aws_iam_role.prod_to_pre_prod_s3_sync_role[0].name]
  policy_arn = aws_iam_policy.prod_to_pre_prod_s3_sync_policy[0].arn
}

