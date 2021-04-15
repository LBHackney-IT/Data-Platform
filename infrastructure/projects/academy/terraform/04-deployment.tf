resource "aws_iam_role" "deployment_role" {
  provider = aws.core
  count    = var.deployment ? 1 : 0

  name = "deployment_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.core_current.account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
EOF

  tags = module.tags.values
}
