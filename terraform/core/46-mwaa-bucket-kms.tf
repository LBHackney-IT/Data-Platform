data "aws_caller_identity" "current" {}

locals {
  custom_key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow CloudWatch Logs to use the KMS key"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "CrossAccountShare"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:RetireGrant",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:Decrypt",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create the KMS key with the custom key policy
resource "aws_kms_key" "mwaa_key" {
  description         = "KMS key for MWAA"
  policy              = local.custom_key_policy
  enable_key_rotation = true
  tags                = module.tags.values
}

# Create an alias for the KMS key for better readability in the console
resource "aws_kms_alias" "mwaa_key_alias" {
  name          = "alias/mwaa-key"
  target_key_id = aws_kms_key.mwaa_key.key_id
}

