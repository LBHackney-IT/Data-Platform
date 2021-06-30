locals {
  glue_crawler_excluded_blobs = [
    "*.json",
    "*.txt",
    "*.zip",
    "*.xlsx"
  ]
}

data "aws_iam_policy_document" "glue_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "glue_role" {
  tags = module.tags.values

  name               = "${local.identifier_prefix}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_role.json
}

data "aws_iam_policy_document" "glue_can_write_to_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "full_glue_access" {
  statement {
    effect = "Allow"
    actions = [
      "glue:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "full_glue_access" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-full-glue-access")
  policy = data.aws_iam_policy_document.full_glue_access.json
}

resource "aws_iam_policy" "glue_can_write_to_cloudwatch" {
  tags = module.tags.values

  name   = "${local.identifier_prefix}-glue-can-write-to-cloudwatch"
  policy = data.aws_iam_policy_document.glue_can_write_to_cloudwatch.json
}

resource "aws_iam_role_policy_attachment" "glue_role_can_write_to_cloudwatch" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
}

resource "aws_iam_policy" "glue_access_policy" {
  tags = module.tags.values

  name = "${local.identifier_prefix}-glue-access-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect : "Allow",
        Action : [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "iam:ListRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
        ],
        Resource : [
          "*"
        ]
      },
      {
        Effect : "Allow",
        Action : "s3:*",
        Resource : [
          "${module.landing_zone.bucket_arn}/*",
          "${module.raw_zone.bucket_arn}/*",
          "${module.refined_zone.bucket_arn}/*",
          "${module.trusted_zone.bucket_arn}/*",
          "${module.glue_scripts.bucket_arn}/*",
          "${module.glue_temp_storage.bucket_arn}/*"
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ],
        Resource : [
          module.glue_scripts.kms_key_arn,
          module.glue_temp_storage.kms_key_arn,
          module.athena_storage.kms_key_arn,
          module.landing_zone.kms_key_arn,
          module.raw_zone.kms_key_arn,
          module.refined_zone.kms_key_arn,
          module.trusted_zone.kms_key_arn,
          aws_kms_key.secrets_manager_key.arn,
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "secretsmanager:GetSecretValue"
        ],
        Resource : [
          aws_secretsmanager_secret.sheets_credentials_housing.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_glue_access_policy_to_glue_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_access_policy.arn
}

