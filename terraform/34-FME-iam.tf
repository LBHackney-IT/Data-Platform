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

resource "aws_iam_user_policy" "fme_user_policy" {
  name = "${local.short_identifier_prefix}fme-user-policy"
  user = aws_iam_user.fme_user.name
  policy = data.aws_iam_policy_document.fme_can_write_to_s3_and_athena.json
}

data "aws_iam_policy_document" "fme_can_write_to_s3_and_athena" {
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
      "${module.athena_storage.bucket_arn}/primary/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.refined_zone.bucket_arn}/*",
      "${module.trusted_zone.bucket_arn}/*",
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
    ]
  }

  statement {
    effect = "Allow"
    actions = [
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