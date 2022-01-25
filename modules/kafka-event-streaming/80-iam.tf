data "aws_iam_policy_document" "kafka_connector_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["kafkaconnect.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "kafka_connector" {
  tags = var.tags

  name               = "${var.identifier_prefix}kafka-connector"
  assume_role_policy = data.aws_iam_policy_document.kafka_connector_assume_role.json
}

data "aws_iam_policy_document" "kafka_connector_write_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      var.bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:ListObjectsV2",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      var.bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = [
      var.kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "kafka_connector_cloud_watch" {
  statement {
    effect = "Allow"
    sid = "CloudWatchLogWriting"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    effect = "Allow"
    sid = "CloudWatchMetricRecording"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "kafka_connector_kafka_access" {
  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:AlterCluster",
      "kafka-cluster:DescribeCluster"
    ]
    resources = [
      aws_msk_cluster.kafka_cluster.arn
    ]
  }
  statement {
    effect = "Allow"
    action = [
      "kafka-cluster:*Topic*",
      "kafka-cluster:WriteData",
      "kafka-cluster:ReadData"
    ]
    resources = [
      aws_msk_cluster.kafka_cluster.arn
    ]
  }
  statement {
    effect = "Allow"
    action = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup"
    ]
    resources = [
      aws_msk_cluster.kafka_cluster.arn
    ]
  }
}

data "aws_iam_policy_document" "kafka_connector" {
  source_policy_documents = [
    data.aws_iam_policy_document.kafka_connector_write_to_s3.json,
    data.aws_iam_policy_document.kafka_connector_cloud_watch.json,
    data.aws_iam_policy_document.kafka_connector_kafka_access.json
  ]
}

resource "aws_iam_policy" "kafka_connector" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}kafka-connector")
  policy = data.aws_iam_policy_document.kafka_connector.json
}

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