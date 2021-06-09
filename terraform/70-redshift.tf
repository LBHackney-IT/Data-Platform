data "aws_iam_policy_document" "redshift_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["redshift.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "redshift_role" {
  tags = module.tags.values

  name = "${local.identifier_prefix}-redshift-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_role.json
}

resource "aws_iam_policy" "redshift_access_policy" {
  name = "${local.identifier_prefix}-redshift-access-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect : "Allow",
        Action : [
          "glue:GetDatabase",
          "glue:CreateDatabase",
          "glue:CreateTable",
          "glue:GetTable"
        ],
        Resource : [
          "*" # to do: restric access so it's not to everything
        ]
      },
      {
        Effect : "Allow",
        Action : "s3:*",
        Resource : [
          "${module.landing_zone.bucket_arn}/*",
          module.landing_zone.bucket_arn,
          "${module.refined_zone.bucket_arn}/*",
          module.refined_zone.bucket_arn,
          "${module.trusted_zone.bucket_arn}/*",
          module.trusted_zone.bucket_arn,
          "${module.raw_zone.bucket_arn}/*",
          module.raw_zone.bucket_arn
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "s3:ListAccessPointsForObjectLambda",
          "s3:GetAccessPoint",
          "s3:GetAccountPublicAccessBlock",
          "s3:ListAccessPoints"
        ],
        Resource : [
          "*"
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "kms:DescribeCustomKeyStores"
        ],
        Resource : [
          module.landing_zone.kms_key_arn,
          module.raw_zone.kms_key_arn,
          module.refined_zone.kms_key_arn,
          module.trusted_zone.kms_key_arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_redshift_role" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_access_policy.arn
}

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier = "${local.identifier_prefix}-redshift-cluster"
  database_name      = "data_platform"
  master_username    = "data_engineers"
  master_password    = "Mustbe8characters"
  node_type          = "dc2.large"
  cluster_type       = "single-node"
  iam_roles          = [aws_iam_role.redshift_role.arn]
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift.name
  tags              = module.tags.values

}

resource "aws_redshift_subnet_group" "redshift" {
  name       = "${local.identifier_prefix}-redshift"
  subnet_ids = local.subnet_ids_list

  tags = module.tags.values

}
