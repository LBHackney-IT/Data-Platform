resource "aws_s3_bucket" "service_api_qlik_replica" {
  provider = aws.ireland

  bucket = format("social-care-case-viewer-api-qlik-bucket-replica-%s", lower(var.environment))

  versioning {
    enabled = true
  }
}

resource "aws_iam_role" "service_api_qlik_replica" {
  provider = aws.core

  name = "social-care-case-viewer-api-qlik-bucket-replica-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "s3.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

resource "aws_iam_policy" "service_api_qlik_replica" {
  provider = aws.core

  name = "social-care-case-viewer-api-qlik-bucket-replica-role-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        "Effect": "Allow",
        "Resource": [
          aws_s3_bucket.service_api_qlik.arn
        ]
      },
      {
        "Action": [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ],
        "Effect": "Allow",
        "Resource": [
          "${aws_s3_bucket.service_api_qlik.arn}/*"
        ]
      },
      {
        "Action": [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ],
        "Effect": "Allow",
        "Resource": "${aws_s3_bucket.service_api_qlik_replica.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "service_api_qlik_replica" {
  provider = aws.core

  role       = aws_iam_role.service_api_qlik_replica.name
  policy_arn = aws_iam_policy.service_api_qlik_replica.arn
}
