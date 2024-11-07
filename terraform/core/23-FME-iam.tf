resource "aws_iam_user" "fme_user" {
  name = "${local.short_identifier_prefix}fme-user"

  tags = module.tags.values
}

resource "aws_iam_access_key" "fme_access_key" {
  user = aws_iam_user.fme_user.name
}

resource "aws_secretsmanager_secret" "fme_access_key" {
  tags = module.tags.values

  name_prefix = "${local.short_identifier_prefix}fme-access-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret_version" "fme_user_access_key_version" {
  secret_id     = aws_secretsmanager_secret.fme_access_key.id
  secret_string = aws_iam_access_key.fme_access_key.secret
}

resource "aws_iam_policy" "fme_user_s3_access_policy" {
  name   = "${local.short_identifier_prefix}fme-user-s3-access-policy"
  policy = data.aws_iam_policy_document.fme_access_to_s3.json
  tags   = module.tags.values
}

resource "aws_iam_user_policy_attachment" "fme_user_s3_access_policy" {
  user       = aws_iam_user.fme_user.name
  policy_arn = aws_iam_policy.fme_user_s3_access_policy.arn
}

resource "aws_iam_policy" "fme_user_glue_athena_access_policy" {
  name   = "${local.short_identifier_prefix}fme-user-glue-athena-access-policy"
  policy = data.aws_iam_policy_document.fme_access_to_athena_and_glue.json
  tags   = module.tags.values
}

resource "aws_iam_user_policy_attachment" "fme_user_glue_athena_access_policy" {
  user       = aws_iam_user.fme_user.name
  policy_arn = aws_iam_policy.fme_user_glue_athena_access_policy.arn
}

data "aws_iam_policy_document" "fme_access_to_athena_and_glue" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
      "glue:CreatePartition",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "athena:ListEngineVersions",
      "athena:ListWorkGroups",
      "athena:ListDataCatalogs",
      "athena:ListDatabases",
      "athena:GetDatabase",
      "athena:ListTableMetadata",
      "athena:GetTableMetadata",
      "athena:BatchGetQueryExecution",
      "athena:GetQueryExecution",
      "athena:ListQueryExecutions",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
      "athena:GetQueryResults",
      "athena:GetQueryResultsStream",
      "athena:CreateNamedQuery",
      "athena:GetNamedQuery",
      "athena:BatchGetNamedQuery",
      "athena:ListNamedQueries",
      "athena:DeleteNamedQuery",
      "athena:CreatePreparedStatement",
      "athena:GetPreparedStatement",
      "athena:ListPreparedStatements",
      "athena:UpdatePreparedStatement",
      "athena:DeletePreparedStatement"
    ]
    resources = [
      "*"
    ]
  }
}


data "aws_iam_policy_document" "fme_access_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = concat(
      [
        "${module.athena_storage.bucket_arn}/primary/*",
      ],
      [
        for folder in [
          "unrestricted",
          "data-and-insight",
          "env-enforcement",
          "env-services",
          "housing",
          "parking",
          "planning",
          "streetscene"
          ] : [
          "${module.raw_zone.bucket_arn}/${folder}/*",
          "${module.refined_zone.bucket_arn}/${folder}/*",
          "${module.trusted_zone.bucket_arn}/${folder}/*"
        ]
      ]...
    )
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.raw_zone.bucket_arn}/unrestricted/*",
      "${module.athena_storage.bucket_arn}/primary/*"
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
      module.athena_storage.kms_key_arn,
      module.raw_zone.kms_key_arn,
      module.refined_zone.kms_key_arn,
      module.trusted_zone.kms_key_arn
    ]
  }
}
