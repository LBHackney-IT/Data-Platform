resource "aws_iam_role" "mwaa_role" {
  name = "mwaa_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = [
            "airflow-env.amazonaws.com",
            "airflow.amazonaws.com"
          ]
        }
      }
    ]
  })
  tags = module.tags.values
}

resource "aws_iam_role_policy" "mwaa_role_policy" {
  name = "mwaa_role_policy"
  role = aws_iam_role.mwaa_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "airflow:PublishMetrics",
        Resource = "arn:aws:airflow:*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*"
        ],
        Resource = [
          "${aws_s3_bucket.mwaa_bucket.arn}",
          "${aws_s3_bucket.mwaa_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups"
        ],
        Resource = "arn:aws:logs:*"
      },
      {
        Effect   = "Allow",
        Action   = "cloudwatch:PutMetricData",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        Resource = "arn:aws:sqs:eu-west-2:*:airflow-celery-*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ],
        Resource = aws_kms_key.mwaa_key.arn
      }
    ]
  })
}


# Security group for MWAA - self-referencing and allowing all traffic out
# This is recommended in the doc, Matt recommended at current stage.
# https://docs.aws.amazon.com/mwaa/latest/userguide/vpc-security.html
resource "aws_security_group" "mwaa_sg" {
  name        = "mwaa_sg"
  description = "Security group for MWAA"
  vpc_id      = data.aws_vpc.network.id
  tags        = module.tags.values
}

resource "aws_security_group_rule" "mwaa_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.mwaa_sg.id
  source_security_group_id = aws_security_group.mwaa_sg.id
  description              = "Allow all inbound traffic from specific security group"
}

resource "aws_security_group_rule" "mwaa_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.mwaa_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Create a placeholder file in the S3 bucket, S3 does not support the creation of empty folders
# To ensure the folders are created otherwise the MWAA environment will fail to create
resource "aws_s3_bucket_object" "plugins_placeholder" {
  # bucket  = module.mwaa_bucket.bucket_id
  bucket  = aws_s3_bucket.mwaa_bucket.bucket
  key     = "plugins/.placeholder"
  content = ""
}

resource "aws_s3_bucket_object" "dags_placeholder" {
  bucket  = aws_s3_bucket.mwaa_bucket.bucket
  key     = "dags/.placeholder"
  content = ""
}

resource "aws_s3_bucket_object" "requirements_placeholder" {
  bucket  = aws_s3_bucket.mwaa_bucket.bucket
  key     = "requirements/.placeholder"
  content = ""
}

resource "aws_mwaa_environment" "mwaa" {
  # count              = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name               = "${local.identifier_prefix}mwaa-environment"
  airflow_version    = "2.8.1" # Preinstall python 3.11
  environment_class  = "mw1.small"
  execution_role_arn = aws_iam_role.mwaa_role.arn
  source_bucket_arn  = aws_s3_bucket.mwaa_bucket.arn
  dag_s3_path        = "dags/"
  # plugins_s3_path      = "plugins" # Optional
  # requirements_s3_path = "requirements/requirements.txt" # Optional
  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = slice(data.aws_subnets.network.ids, 0, 2) # Must contain no more than 2 subnet IDs.
  }
  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  # To view the Airflow UI, set this to PUBLIC_ONLY or create a mechanism to access the VPC endpoint
  # https://docs.aws.amazon.com/mwaa/latest/userguide/t-create-update-environment.html#t-network-failure
  webserver_access_mode = "PUBLIC_ONLY" # Default is PRIVATE_ONLY
  max_workers           = 5             # Default 10
  min_workers           = 1             # Default 1
  schedulers            = 2             # Must be between 2 and 5
  kms_key               = aws_kms_key.mwaa_key.arn
  tags                  = module.tags.values
}