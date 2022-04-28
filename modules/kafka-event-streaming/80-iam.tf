data "aws_iam_policy_document" "kafka_connector_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["kafkaconnect.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "kafka_connector" {
  tags = var.tags

  name               = "${var.short_identifier_prefix}kafka-connector"
  assume_role_policy = data.aws_iam_policy_document.kafka_connector_assume_role.json
}

data "aws_iam_policy_document" "kafka_connector_write_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = [
      var.s3_bucket_to_write_to.bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Put*",
      "s3:Get*",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [
      "${var.s3_bucket_to_write_to.bucket_arn}/*"
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
      var.s3_bucket_to_write_to.kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "kafka_connector_cloud_watch" {
  statement {
    effect = "Allow"
    sid    = "CloudWatchLogWriting"
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
    sid    = "CloudWatchMetricRecording"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*"
    ]
  }
}

# TODO: make this less permissive
data "aws_iam_policy_document" "glue_schema_access" {
  statement {
    effect    = "Allow"
    sid       = "GetSchema"
    actions   = ["glue:*"]
    resources = ["*"]
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
    actions = [
      "kafka-cluster:*Topic*",
      "kafka-cluster:WriteData",
      "kafka-cluster:ReadData",
    ]
    resources = [
      aws_msk_cluster.kafka_cluster.arn, # dont need?
      "arn:aws:kafka:eu-west-2:${data.aws_caller_identity.current.account_id}:topic/${aws_msk_cluster.kafka_cluster.cluster_name}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup"
    ]
    resources = [
      aws_msk_cluster.kafka_cluster.arn, # dont need?
      "arn:aws:kafka:eu-west-2:${data.aws_caller_identity.current.account_id}:group/${aws_msk_cluster.kafka_cluster.cluster_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "kafka_connector" {
  source_policy_documents = [
    data.aws_iam_policy_document.kafka_connector_write_to_s3.json,
    data.aws_iam_policy_document.kafka_connector_cloud_watch.json,
    data.aws_iam_policy_document.kafka_connector_kafka_access.json,
    data.aws_iam_policy_document.glue_schema_access.json
  ]
}

resource "aws_iam_policy" "kafka_connector" {
  tags = var.tags

  name   = lower("${var.short_identifier_prefix}kafka-connector")
  policy = data.aws_iam_policy_document.kafka_connector.json
}

resource "aws_iam_role_policy_attachment" "kafka_connector" {
  role       = aws_iam_role.kafka_connector.name
  policy_arn = aws_iam_policy.kafka_connector.arn
}