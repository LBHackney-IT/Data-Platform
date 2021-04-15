resource "aws_iam_user" "circleci_assume_role" {
  provider = aws.core

  name = "circleci-assume-role-user"

  tags = module.tags.values
}

resource "aws_iam_user_policy" "circleci_assume_role" {
  provider = aws.core

  name = "circleci-assume-role-user-policy"
  user = aws_iam_user.circleci_assume_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = aws_iam_role.circleci_assume_role.arn
      },
    ]
  })
}

resource "aws_iam_role" "circleci_assume_role" {
  provider = aws.core

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
  name = "circleci-assume-role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]

  tags = module.tags.values
}

resource "aws_iam_access_key" "circleci_assume_role_user" {
  provider = aws.core

  user = aws_iam_user.circleci_assume_role.name
}
