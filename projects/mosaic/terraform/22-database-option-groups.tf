resource "aws_iam_role" "mosaic_mssql_iam_role" {
  provider = aws.core

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  name               = "mosaic_mssql_iam_role"

  tags = module.tags.values
}

resource "aws_iam_policy" "mosaic_mssql_iam_role" {
  provider = aws.core

  name        = "mosaic_mssql_iam_policy"
  path        = "/"
  description = "Mosaic MySQL IAM Policy."

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::social-care-recovery"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectMetaData",
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
            ],
            "Resource": [
                "arn:aws:s3:::social-care-recovery/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "mosaic_mssql_iam_policy_attachment" {
  provider = aws.core

  role       = aws_iam_role.mosaic_mssql_iam_role.name
  policy_arn = aws_iam_policy.mosaic_mssql_iam_role.arn
}
