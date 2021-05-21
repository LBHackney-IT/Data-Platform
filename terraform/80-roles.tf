data "aws_iam_policy_document" "sso_trusted_relationship" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::120038763019:saml-provider/AWSSSO_9040e5ede958c40d_DO_NOT_DELETE"]
      type = "Federated"
    }
    principals {
      identifiers = ["arn:aws:iam::484466746276:role/aws-reserved/sso.amazonaws.com/eu-west-1/AWSReservedSSO_AWSAdministratorAccess_2cff52f8dbae1fd6"]
      type = "AWS"
    }
    actions = [
      "sts:AssumeRole",
      "sts:AssumeRoleWithSAML",
      "sts:TagSession"
    ]
  }
}


data "aws_iam_policy_document" "power_user_parking" {
  statement {
    effect = "Allow"
    actions = [
      "athena:*",
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }

  // Glue Access
  statement {
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      // "glue:UpdateDatabase",
      // "glue:CreateTable",
      // "glue:DeleteTable",
      // "glue:BatchDeleteTable",
      // "glue:UpdateTable",
      "glue:GetTable",
      "glue:GetTables",
      // "glue:BatchCreatePartition",
      // "glue:CreatePartition",
      // "glue:DeletePartition",
      // "glue:BatchDeletePartition",
      // "glue:UpdatePartition",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:ListBucket"
    ]
    resources = [
      module.landing_zone.bucket_arn,
      "${module.landing_zone.bucket_arn}/repairs/*",
      "${module.raw_zone.bucket_arn}/repairs/*",
      "${module.refined_zone.bucket_arn}/repairs/*",
      "${module.trusted_zone.bucket_arn}/repairs/*"
    ]
  }
}

resource "aws_iam_role" "power_user_parking" {
  name = "AWS_SSO_${upper(local.application_snake)}_POWER_USER_PARKING"
  assume_role_policy = data.aws_iam_policy_document.sso_trusted_relationship.json
}

resource "aws_iam_policy" "power_user_parking" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-power-user-parking")
  policy = data.aws_iam_policy_document.power_user_parking.json
}

resource "aws_iam_role_policy_attachment" "power_user_parking" {
  role       = aws_iam_role.power_user_parking.name
  policy_arn = aws_iam_policy.power_user_parking.arn
}