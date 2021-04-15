resource "aws_s3_bucket" "data_platform_raw" {
  provider = aws.core
  bucket   = "hackney-data-platform-raw-staging-mtsandbox"
}

resource "aws_s3_bucket" "data_platform_glue_script" {
  provider = aws.core
  bucket   = "hackney-data-platform-glue-script"
}

resource "aws_s3_bucket" "data_platform_glue_temp_storage" {
  provider = aws.core
  bucket   = "hackney-data-platform-glue-temp-storage"
}

resource "aws_iam_role" "glue" {
  provider = aws.core
  name = "data-platform-glue-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "glue_access_policy" {
  provider = aws.core
  name = "data-platform-glue-access-policy"
  policy = <<POLICY
{
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "glue:*",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListAllMyBuckets",
                "iam:ListRolePolicies",
                "iam:GetRole",
                "iam:GetRolePolicy",
                "cloudwatch:PutMetricData"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "${aws_s3_bucket.data_platform_raw.arn}/*",
                "${aws_s3_bucket.data_platform_glue_temp_storage.arn}/*",
                "${aws_s3_bucket.data_platform_glue_script.arn}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:AssociateKmsKey"
            ],
            "Resource": [
                "arn:aws:logs:*:*:/aws-glue/*"
            ]
        }
    ]
}
}
POLICY
}

resource "aws_iam_role_policy_attachment" "attach_glue_access_policy" {
  provider = aws.core
  role       = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue_access_policy.arn
}

resource "aws_s3_bucket_policy" "data_platform_raw_bucket_policy" {
  provider = aws.core
  bucket   = aws_s3_bucket.data_platform_raw.id
  policy   = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"ListBucket",
      "Effect":"Allow",
      "Principal": {"AWS": ["arn:aws:iam::261219435789:root", "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463"]},
      "Action":["s3:ListBucket"],
      "Resource":"${aws_s3_bucket.data_platform_raw.arn}"
    },
    {
      "Sid":"AddCannedAcl",
      "Effect":"Allow",
      "Principal": {"AWS": ["arn:aws:iam::261219435789:root", "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463"]},
      "Action":["s3:PutObject","s3:PutObjectAcl"],
      "Resource":"${aws_s3_bucket.data_platform_raw.arn}/social-care/*",
      "Condition": {
          "StringEquals": {
              "s3:x-amz-acl": "bucket-owner-full-control"
          }
      }
    }
  ]
}
POLICY
}
