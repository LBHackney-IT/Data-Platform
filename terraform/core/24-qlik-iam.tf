resource "aws_iam_user" "qlik_user" {
  name          = "${local.short_identifier_prefix}qlik-user"
  force_destroy = !local.is_live_environment
  tags          = module.tags.values
}

resource "aws_iam_access_key" "qlik_access_key" {
  user = aws_iam_user.qlik_user.name
}

resource "aws_secretsmanager_secret" "qlik_access_key" {
  tags = module.tags.values

  name_prefix = "${local.short_identifier_prefix}qlik-access-key"

  kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret_version" "qlik_user_access_key_version" {
  secret_id = aws_secretsmanager_secret.qlik_access_key.id
  secret_string = jsonencode({
    "Access Key ID"     = aws_iam_access_key.qlik_access_key.id
    "Secret Access key" = aws_iam_access_key.qlik_access_key.secret
  })
}

resource "aws_iam_user_policy" "qlik_user_policy" {
  name   = "${local.short_identifier_prefix}qlik-user-policy"
  user   = aws_iam_user.qlik_user.name
  policy = data.aws_iam_policy_document.qlik_can_read_from_s3_and_athena.json
}

data "aws_iam_policy_document" "qlik_can_read_from_s3_and_athena" {
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
    resources = [
      "${module.raw_zone.bucket_arn}/*",
      "${module.refined_zone.bucket_arn}/*",
      "${module.trusted_zone.bucket_arn}/*",
      "${module.athena_storage.bucket_arn}/*",
      "${module.cloudtrail_storage.bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${module.athena_storage.bucket_arn}/*"
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
      module.trusted_zone.kms_key_arn,
      module.cloudtrail_storage.kms_key_arn
    ]
  }

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
