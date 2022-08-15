data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com",
        "kafka.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

locals {
  command                 = "make install-requirements"
  confluent_kafka_command = "docker run -v \"$PWD\":/var/task \"lambci/lambda:build-python3.8\" /bin/sh -c \"pip install -r requirements.txt -t python/lib/python3.8/site-packages/; exit\""
}

resource "aws_iam_role" "lambda" {
  tags               = var.tags
  name               = lower("${var.identifier_prefix}${var.lambda_name}")
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kafka:DescribeCluster",
      "kafka:DescribeClusterV2",
      "kafka:GetBootstrapBrokers"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:AlterCluster",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:ReadData",
      "kafka-cluster:WriteData",
      "kafka-cluster:*Topic*",
      "kafka-cluster:DescribeClusterDynamicConfiguration"
    ]
    resources = [
      var.kafka_cluster_arn,
      "arn:aws:kafka:eu-west-2:${data.aws_caller_identity.current.account_id}:cluster/${var.kafka_cluster_name}/*",
      "arn:aws:kafka:eu-west-2:${data.aws_caller_identity.current.account_id}:topic/${var.kafka_cluster_name}/*",
      "arn:aws:kafka:eu-west-2:${data.aws_caller_identity.current.account_id}:group/${var.kafka_cluster_name}/*"
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
      var.kafka_cluster_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "lambda" {
  tags = var.tags

  name_prefix = lower("${var.identifier_prefix}${var.lambda_name}")
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {

  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}


resource "null_resource" "run_install_requirements" {
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../../lambdas/kafka_test/*") : filesha1("${path.module}/${f}")]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.command
    working_dir = "${path.module}/../../../lambdas/kafka_test/"
  }
}

data "null_data_source" "wait_for_lambda_exporter" {
  inputs = {
    # This ensures that this data resource will not be evaluated until
    # after the null_resource has been created.
    lambda_exporter_id = null_resource.run_install_requirements.id

    # This value gives us something to implicitly depend on
    # in the archive_file below.
    source_dir = "../../lambdas/kafka_test"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = data.null_data_source.wait_for_lambda_exporter.outputs["source_dir"]
  output_path = "../../lambdas/kafka_test.zip"
}

resource "aws_s3_bucket_object" "lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "kafka_test.zip"
  source      = data.archive_file.lambda.output_path
  acl         = "private"
  source_hash = null_resource.run_install_requirements.triggers["dir_sha1"]
}

resource "aws_lambda_function" "lambda" {
  tags = var.tags

  role             = aws_iam_role.lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  function_name    = lower("${var.identifier_prefix}${var.lambda_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_bucket_object.lambda.key
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 900
  memory_size      = 256

  ephemeral_storage {
    size = 512
  }
  environment {
    variables = var.lambda_environment_variables
  }

  vpc_config {
    security_group_ids = var.kafka_security_group_id
    subnet_ids         = var.subnet_ids
  }
}

