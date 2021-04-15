resource "aws_iam_user" "service_api_qlik_bucket_user" {
  provider = aws.core

  name = "social-care-case-viewer-api-qlik-bucket-user"

  tags = module.tags.values
}

resource "aws_iam_user_policy" "service_api_qlik_bucket_user" {
  provider = aws.core

  name = "social-care-case-viewer-api-qlik-bucket-user-policy"
  user = aws_iam_user.service_api_qlik_bucket_user.name

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowServiceAPIQlikBucketAccess",
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": [
          aws_s3_bucket.service_api_qlik.arn,
          "${aws_s3_bucket.service_api_qlik.arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "service_api_qlik_bucket_user" {
  provider = aws.core

  user = aws_iam_user.service_api_qlik_bucket_user.name
}

# Temporary resources to retrieve secret keys to enable Qlik import to service API S3 bucket
resource "aws_secretsmanager_secret" "service_api_qlik_bucket_user_access_key_id" {
  provider = aws.core

  name = "social-care-case-viewer-api-qlik-bucket-user-access-key-id"
}

resource "aws_secretsmanager_secret_version" "service_api_qlik_bucket_user_access_key_id" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.service_api_qlik_bucket_user_access_key_id.id
  secret_string = aws_iam_access_key.service_api_qlik_bucket_user.id
}

resource "aws_secretsmanager_secret" "service_api_qlik_bucket_user_access_key" {
  provider = aws.core

  name = "social-care-case-viewer-api-qlik-bucket-user-access-key"
}

resource "aws_secretsmanager_secret_version" "service_api_qlik_bucket_user_access_key" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.service_api_qlik_bucket_user_access_key.id
  secret_string = aws_iam_access_key.service_api_qlik_bucket_user.secret
}
