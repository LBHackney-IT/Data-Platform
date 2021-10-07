resource "aws_iam_user" "liberator_user" {
    name = "liberator-assume-role-user"

    tags = module.tags.values
}

resource "aws_iam_access_key" "liberator_access_key" {
    user =  aws_iam_user.liberator_user.name
}

resource "aws_iam_user_policy" "liberator_user_policy" {
    name = "liberator-assume-role-user-policy"
    user = aws_iam_user.liberator_user.name

    policy = data.aws_iam_policy_document.liberator_can_write_to_s3.json
}

data "aws_iam_policy_document" "liberator_can_write_to_s3" {
    statement {
        effect = "Allow"
        actions = [
            "s3:ListBucket",
            "s3:GetBucketLocation"
        ]
        resources = [
            "arn:aws:s3:::dataplatform-stg-liberator-data-storage/parking/"
        ]
    }

    statement {
      effect = "Allow"
      actions = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion"
        ]
        resources = [
            "arn:aws:s3:::dataplatform-stg-liberator-data-storage/parking/*"
        ]
    }
}

resource "aws_secretsmanager_secret" "liberator_user_private_key" {
    tags = module.tags.values

    name_prefix = "${local.short_identifier_prefix}liberator-user-private-key"

    kms_key_id = aws_kms_key.secrets_manager_key.id
}

resource "aws_secretsmanager_secret_version" "liberator_user_private_key_version" {
    secret_id = aws_secretsmanager_secret.liberator_user_private_key.id
    secret_string = aws_iam_access_key.liberator_access_key.secret
}
