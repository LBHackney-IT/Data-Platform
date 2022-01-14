#locals {
#  default_arn = [
#    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
#  ]
#}
#
#resource "aws_iam_user" "kafka_test" {
#  name = "kafka_test"
#  tags = {
#    name = "kafka_test"
#  }
#}
#
#data "aws_iam_policy_document" "key_policy" {
#  statement {
#    effect = "Allow"
#    actions = [
#      "sts:AssumeRole"
#    ]
#    resources = [
#      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.assume_mck_role.name}"
#    ]
#    principles {
#      type = "AWS"
#      identifiers = local.default_arn
#    }
#  }
#  statement {
#    sid = "CrossAccountShare"
#    effect = "Allow"
#    actions = [
#    ]
#    resources = [
#    ]
#    principals {
#      type = "AWS"
#      identifiers = concat(var.role_arns_to_share_access_with, local.default_arn)
#    }
#  }
#}
#
#resource "aws_iam_policy" "assume_mck_role" {
#  name        = "assume_mck_role"
#  description = "allow assuming prod_s3 role"
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Effect   = "Allow",
#        Action   = "sts:AssumeRole",
#        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.assume_mck_role.name}"
#    }]
#  })
#}
#
#resource "aws_iam_user_policy_attachment" "assume_mck_role" {
#  user       = aws_iam_user.kafka_test.name
#  policy_arn = aws_iam_policy.assume_mck_role.arn
#}
#
#resource "aws_iam_user_policy_attachment" "prod_s3" {
#  user       = aws_iam_user.kafka_test.name
#  policy_arn = aws_iam_policy.assume_mck_role.arn
#}