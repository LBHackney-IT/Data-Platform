resource "aws_iam_role" "mwaa_role" {
  name = "mwaa_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "airflow-env.amazonaws.com"
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
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Effect = "Allow",
        Resource = [
          module.mwaa_bucket.bucket_arn,
          "${module.mwaa_bucket.bucket_arn}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "iam:PassRole"
        ],
        Effect   = "Allow",
        Resource = aws_iam_role.mwaa_role.arn
      },
      {
        Action = [
          "s3:GetAccountPublicAccessBlock",
          "s3:PutAccountPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock"
        ],
        Effect   = "Allow",
        Resource = [
          module.mwaa_bucket.bucket_arn,
          "${module.mwaa_bucket.bucket_arn}/*"
        ]
      }
    ]
  })
}

# Security group for MWAA to allow HTTPS traffic on port 443 and all outbound traffic
# We definate refine it to limit the traffic later (let's keep it simple for now)
resource "aws_security_group" "mwaa_sg" {
  name        = "mwaa_sg"
  description = "Security group for MWAA"
  vpc_id      = data.aws_vpc.network.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #   egress {
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  tags = module.tags.values
}


# Create a placeholder file in the S3 bucket, S3 does not support the creation of empty folders
# To ensure the folders are created otherwise the MWAA environment will fail to create
resource "aws_s3_bucket_object" "plugins_placeholder" {
  bucket  = module.mwaa_bucket.bucket_id
  key     = "plugins/.placeholder"
  content = ""
}

resource "aws_s3_bucket_object" "dags_placeholder" {
  bucket  = module.mwaa_bucket.bucket_id
  key     = "dags/.placeholder"
  content = ""
}

resource "aws_s3_bucket_object" "requirements_placeholder" {
  bucket  = module.mwaa_bucket.bucket_id
  key     = "requirements/requirements.txt"
  content = ""
}

resource "aws_mwaa_environment" "mwaa" {
  name               = "data_platform_mwaa_environment"
  airflow_version    = "2.8.1" # Preinstall python 3.11
  environment_class  = "mw1.small"
  execution_role_arn = aws_iam_role.mwaa_role.arn
  source_bucket_arn  = module.mwaa_bucket.bucket_arn
  dag_s3_path        = "dags"
  #   plugins_s3_path      = "plugins"
  requirements_s3_path = "requirements/requirements.txt"
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
  # default is PRIVATE_ONLY
  # to view the Airflow UI, set this to PUBLIC_ONLY or create a mechanism to access the VPC endpoint
  # https://docs.aws.amazon.com/mwaa/latest/userguide/t-create-update-environment.html#t-network-failure
  webserver_access_mode = "PUBLIC_ONLY"
  max_workers           = 5
  min_workers           = 1
  kms_key               = module.mwaa_bucket.kms_key_arn
  tags                  = module.tags.values
}
