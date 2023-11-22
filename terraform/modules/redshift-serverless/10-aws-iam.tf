data "aws_iam_policy_document" "redshift_serverless_role" {
    statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["redshift.amazonaws.com"]
      type        = "Service"
    }
  }
} 

resource "aws_iam_role" "redshift_serverless_role" {
  tags = var.tags

  name = "${var.identifier_prefix}-redshift-serverless-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_serverless_role.json
}

data "aws_iam_policy_document" "redshift_serverless" {
  statement {
      actions = [
          "s3:ListBucket",
          "s3:GetObject"
      ]
      #should this have access to landing zone?
      resources = [
      "${var.landing_zone_bucket_arn}/*",
      var.landing_zone_bucket_arn,
      "${var.refined_zone_bucket_arn}/*",
      var.refined_zone_bucket_arn,
      "${var.trusted_zone_bucket_arn}/*",
      var.trusted_zone_bucket_arn,
      "${var.raw_zone_bucket_arn}/*",
      var.raw_zone_bucket_arn
      ]
  }

  statement {
    actions = [
      "glue:*"
    ]

    resources = [
      "*",
    ]
  }

    statement {
        actions = [
            "kms:Decrypt",
        ]
        resources = [
            var.landing_zone_kms_key_arn,
            var.raw_zone_kms_key_arn,
            var.refined_zone_kms_key_arn,
            var.trusted_zone_kms_key_arn,
        ]
  }
}

resource "aws_iam_policy" "redshift_serverless_access_policy" {
  name = "${var.identifier_prefix}-redshift-serverless-access-policy"
  policy = data.aws_iam_policy_document.redshift_serverless.json
}

resource "aws_iam_role_policy_attachment" "redshift_serverless_role_policy_attachment" {
  role = aws_iam_role.redshift_serverless_role.name
  policy_arn = aws_iam_policy.redshift_serverless_access_policy.arn
}
