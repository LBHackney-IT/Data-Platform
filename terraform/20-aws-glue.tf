locals {
  crawler_excluded_blogs = [
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

resource "aws_iam_policy" "glue_access_policy" {
  name = "${local.identifier_prefix}-glue-access-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect : "Allow",
        Action : [
          "glue:*",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "iam:ListRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "cloudwatch:PutMetricData",
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
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:AssociateKmsKey"
        ],
        Resource : [
          "arn:aws:logs:*:*:/aws-glue/*"
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
          aws_kms_key.sheets_credentials.arn,
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

resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${local.identifier_prefix}-landing-zone-database"
}

resource "aws_glue_crawler" "landing_zone_housing_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_catalog_database.name
  name          = "${local.identifier_prefix}-landing-zone-housing-crawler"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_"

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/housing"
    exclusions = local.crawler_excluded_blogs
  }
}

resource "aws_glue_crawler" "landing_zone_test_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_catalog_database.name
  name          = "${local.identifier_prefix}-landing-zone-test-crawler"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "test_"

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/test"
    exclusions = local.crawler_excluded_blogs
  }
}

resource "aws_glue_crawler" "landing_zone_parking_crawler" {
  count = terraform.workspace == "default" ? 1 : 0
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_catalog_database.name
  name          = "${local.identifier_prefix}-landing-zone-parking-crawler"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "parking_"

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/parking"
    exclusions = local.crawler_excluded_blogs
  }
}

resource "aws_glue_catalog_database" "landing_zone_liberator" {
  name = "${local.identifier_prefix}-liberator-landing-zone"
}

resource "aws_glue_crawler" "landing_zone_liberator" {
  count = terraform.workspace == "default" ? 1 : 0
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_liberator.name
  name          = "${local.identifier_prefix}-landing-zone-liberator"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/parking/liberator"
    exclusions = local.crawler_excluded_blogs
  }
}

resource "aws_glue_trigger" "landing_zone_liberator_crawler_trigger" {
  count = terraform.workspace == "default" ? 1 : 0
  tags = module.tags.values

  name          = "${local.identifier_prefix} Landing Zone Liberator Crawler"
  type          = "ON_DEMAND"
  enabled       = true
  workflow_name = aws_glue_workflow.liberator_data.name

  actions {
    crawler_name = aws_glue_crawler.landing_zone_liberator.name
  }
}

// ==== RAW ZONE ===========
resource "aws_glue_catalog_database" "raw_zone_catalog_database" {
  name = "${local.identifier_prefix}-raw-zone-database"
}

resource "aws_glue_catalog_database" "raw_zone_parking_manual_uploads" {
  name = "${local.identifier_prefix}-raw-zone-parking-manual-uploads-database"
}

resource "aws_glue_crawler" "raw_zone_parking_manual_uploads_crawler" {
  count = terraform.workspace == "default" ? 1 : 0
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_parking_manual_uploads.name
  name          = "${local.identifier_prefix}-raw-zone-parking-manual-uploads-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.raw_zone.bucket_id}/parking/manual/"
    exclusions = local.crawler_excluded_blogs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_catalog_database" "landing_zone_data_and_insight_address_matching" {
  count = terraform.workspace == "default" ? 1 : 0
  name  = "${local.identifier_prefix}-data-and-insight-address-matching-landing-zone"
}

resource "aws_glue_crawler" "landing_zone_data_and_insight_address_matching" {
  count = terraform.workspace == "default" ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_data_and_insight_address_matching[count.index].name
  name          = "${local.identifier_prefix}-landing-zone-data-and-insight-address-matching"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/"
    exclusions = local.crawler_excluded_blogs
  }
}

// ==== REFINED ZONE ===========

resource "aws_glue_catalog_database" "refined_zone_liberator" {
  name = "${local.identifier_prefix}-liberator-refined-zone"
}

resource "aws_glue_crawler" "refined_zone_liberator_crawler" {
  count = terraform.workspace == "default" ? 1 : 0
  tags = module.tags.values

  database_name = aws_glue_catalog_database.refined_zone_liberator.name
  name          = "${local.identifier_prefix}-refined-zone-liberator"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/parking/liberator/"
    exclusions = local.crawler_excluded_blogs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}
