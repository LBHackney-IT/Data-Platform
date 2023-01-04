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

resource "aws_iam_policy" "glue_can_write_to_cloudwatch" {
  tags = module.tags.values

  name   = "${local.identifier_prefix}-glue-can-write-to-cloudwatch"
  policy = data.aws_iam_policy_document.glue_can_write_to_cloudwatch.json
}

resource "aws_iam_role_policy_attachment" "glue_role_can_write_to_cloudwatch" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
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

resource "aws_iam_role_policy_attachment" "attach_full_glue_access_to_glue_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.full_glue_access.arn
}

data "aws_iam_policy_document" "use_glue_connection" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVPCs",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["aws-glue-service-resource"]
    }
    resources = [
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:instance/*",
    ]
  }
}

resource "aws_iam_policy" "use_glue_connection" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-use-glue-connection")
  policy = data.aws_iam_policy_document.use_glue_connection.json
}

resource "aws_iam_role_policy_attachment" "attach_use_glue_connection_to_glue_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.use_glue_connection.arn
}

data "aws_iam_policy_document" "access_to_s3_iam_and_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListAllMyBuckets",
      "iam:ListRolePolicies",
      "iam:GetRole",
      "iam:GetRolePolicy",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "${module.landing_zone.bucket_arn}/*",
      "${module.raw_zone.bucket_arn}/*",
      "${module.refined_zone.bucket_arn}/*",
      "${module.trusted_zone.bucket_arn}/*",
      "${module.glue_scripts.bucket_arn}/*",
      "${module.glue_temp_storage.bucket_arn}/*",
      "${module.noiseworks_data_storage.bucket_arn}/*",
      "${module.spark_ui_output_storage.bucket_arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [
      module.glue_scripts.kms_key_arn,
      module.glue_temp_storage.kms_key_arn,
      module.athena_storage.kms_key_arn,
      module.landing_zone.kms_key_arn,
      module.raw_zone.kms_key_arn,
      module.refined_zone.kms_key_arn,
      module.trusted_zone.kms_key_arn,
      module.noiseworks_data_storage.kms_key_arn,
      module.spark_ui_output_storage.kms_key_arn,
      aws_kms_key.secrets_manager_key.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.sheets_credentials_housing.arn,
      aws_secretsmanager_secret.tascomi_api_public_key.id,
      aws_secretsmanager_secret.tascomi_api_private_key.id
    ]
  }
}

resource "aws_iam_policy" "glue_access_to_s3_iam_and_secrets" {
  tags = module.tags.values

  name   = "${local.identifier_prefix}-glue-access-policy"
  policy = data.aws_iam_policy_document.access_to_s3_iam_and_secrets.json
}

resource "aws_iam_role_policy_attachment" "attach_glue_access_to_s3_iam_and_secrets_policy_to_glue_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_access_to_s3_iam_and_secrets.arn
}

data "aws_iam_policy_document" "can_assume_all_roles" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "can_assume_all_roles" {
  tags = module.tags.values

  name   = "${local.short_identifier_prefix}can-assume-all-roles"
  policy = data.aws_iam_policy_document.can_assume_all_roles.json
}

resource "aws_iam_role_policy_attachment" "attach_can_assume_all_roles_to_glue_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.can_assume_all_roles.arn
}
