data "aws_iam_policy_document" "notebook" {
  statement {
    sid = "NotebookCanReadGlueAssetS3Bucket"
    actions = [
      "s3:ListBucket",
      "s3:GetObject*"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::aws-glue-jes-prod-eu-west-2-assets*"
    ]
  }

  statement {
    sid = "NotebookCanWriteToLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/sagemaker/*",
      "arn:aws:logs:*:*:log-group:/aws/sagemaker/*:log-stream:aws-glue-*"
    ]
  }
  statement {
    sid = "NotebookCanUseAndCreateDevEndpoint"
    actions = [
      "glue:UpdateDevEndpoint",
      "glue:GetDevEndpoint",
      "glue:GetDevEndpoints",
      "glue:CreateDevEndpoint"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:devEndpoint/${local.glue_dev_endpoint_config.endpoint_name}"
    ]
  }

  statement {
    sid = "NotebookCanPassDevEndpointRole"
    actions = [
      "iam:PassRole"
    ]
    effect = "Allow"
    resources = [
      var.development_endpoint_role_arn
    ]
  }

  statement {
    sid = "NotebookCanListTags"
    actions = [
      "sagemaker:ListTags"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "notebook_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = ["sagemaker.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_policy" "notebook" {
  tags = var.tags

  name   = "${var.identifier_prefix}notebook-${var.instance_name}"
  policy = data.aws_iam_policy_document.notebook.json
}

resource "aws_iam_role_policy_attachment" "notebook" {
  role       = aws_iam_role.notebook.name
  policy_arn = aws_iam_policy.notebook.arn
}


resource "aws_iam_role" "notebook" {
  tags               = var.tags
  name               = "AWSGlueServiceSageMakerNotebookRole-${var.identifier_prefix}notebook-${var.instance_name}"
  assume_role_policy = data.aws_iam_policy_document.notebook_assume_role.json
}