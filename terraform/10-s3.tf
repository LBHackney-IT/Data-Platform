resource "aws_s3_bucket" "dataplatform_raw" {
  provider = aws.core
  bucket = "hackney-data-platform-raw-staging-mtsandbox"

}

resource "aws_s3_bucket_policy" "aws-s3-lb-logs" {
  provider = aws.core
  bucket = aws_s3_bucket.dataplatform_raw.id
  policy = <<POLICY
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"ListBucket",
      "Effect":"Allow",
      "Principal": {"AWS": ["arn:aws:iam::261219435789:root", "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463"]},
      "Action":["s3:ListBucket"],
      "Resource":"${aws_s3_bucket.dataplatform_raw.arn}"
    },
    {
      "Sid":"AddCannedAcl",
      "Effect":"Allow",
      "Principal": {"AWS": ["arn:aws:iam::261219435789:root", "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463"]},
      "Action":["s3:PutObject","s3:PutObjectAcl"],
      "Resource":"${aws_s3_bucket.dataplatform_raw.arn}/social-care/*",
      "Condition": {
          "StringEquals": {
              "s3:x-amz-acl": "bucket-owner-full-control"
          }
        },
      }
  ]
}
POLICY
}
