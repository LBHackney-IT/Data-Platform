locals {
  environment_variables = [
    { name : "MYSQL_HOST", value : aws_db_instance.ingestion_db.address },
    { name : "MYSQL_USER", value : aws_db_instance.ingestion_db.username },
    { name : "MYSQL_PASS", value : random_password.rds_password.result },
    { name : "RDS_INSTANCE_ID", value : aws_db_instance.ingestion_db.id },
    { name : "BUCKET_NAME", value : var.watched_bucket_name },
  ]

  event_pattern = jsonencode({
    "source" : [
      "aws.s3"
    ],
    "detail-type" : [
      "AWS API Call via CloudTrail"
    ],
    "detail" : {
      "eventSource" : [
        "s3.amazonaws.com"
      ],
      "eventName" : [
        "PutObject",
        "CompleteMultipartUpload",
        "CopyObject"
      ],
      "requestParameters" : {
        "bucketName" : [
          var.watched_bucket_name
        ]
      }
    }
  })
}

data "aws_iam_policy_document" "task_role" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.watched_bucket_name}/*"]
  }

  statement {
    actions   = ["kms:*"]
    effect    = "Allow"
    resources = [var.watched_bucket_kms_key_arn]
  }

  statement {
    actions   = ["rds:CreateDBSnapshot", "rds:DeleteDBSnapshot", "rds:DescribeDBSnapshots"]
    effect    = "Allow"
    resources = ["*"]
  }
}

module "sql_to_parquet" {
  source = "../aws-ecs-fargate-task"

  tags                          = var.tags
  operation_name                = var.instance_name
  ecs_task_role_policy_document = data.aws_iam_policy_document.task_role.json
  aws_subnet_ids                = var.aws_subnet_ids
  ecs_cluster_arn               = var.ecs_cluster_arn
  tasks = [
    {
      cloudwatch_rule_event_pattern = local.event_pattern
      task_cpu                      = 256
      task_memory                   = 512
      environment_variables = [
        { name : "MYSQL_HOST", value : aws_db_instance.ingestion_db.address },
        { name : "MYSQL_USER", value : aws_db_instance.ingestion_db.username },
        { name : "MYSQL_PASS", value : random_password.rds_password.result },
        { name : "RDS_INSTANCE_ID", value : aws_db_instance.ingestion_db.id },
        { name : "BUCKET_NAME", value : var.watched_bucket_name },
      ]
    }
  ]
}
