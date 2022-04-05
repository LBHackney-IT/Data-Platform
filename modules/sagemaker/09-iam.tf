data "aws_iam_policy_document" "notebook" {
  statement {
    sid = "NotebookCanReadS3"
    actions = [
      "s3:ListBucket",
      "s3:GetObject*"
    ]
    effect = "Allow"
    resources = [
      # TODO: refine this 
      "*"
    ]
  }
  statement {
    sid = "NotebookCanDecryptKms"
    actions = [
      "kms:Decrypt",
      "kms:*"
    ]
    effect = "Allow"
    resources = [
      # TODO: refine this 
      "*"
    ]
  }
  statement {
    sid = "NotbookCanWriteToLogs"
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
    sid = "NotebookCanUseDevEndpoint"
    actions = [
      "glue:UpdateDevEndpoint",
      "glue:GetDevEndpoint",
      "glue:GetDevEndpoints"
    ]
    effect = "Allow"
    resources = [
      "${aws_glue_dev_endpoint.glue_endpoint.arn}*"
    ]
  }
  statement {
    sid = "NotebookCanListTags"
    actions = [
      "sagemaker:ListTags"
    ]
    effect = "Allow"
    resources = [
      #   "${aws_sagemaker_notebook_instance.nb.arn}*"
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

  name   = lower("${var.identifier_prefix}notebook")
  policy = data.aws_iam_policy_document.notebook.json
}

resource "aws_iam_role_policy_attachment" "notebook" {
  role       = aws_iam_role.notebook.name
  policy_arn = aws_iam_policy.notebook.arn
}


resource "aws_iam_role" "notebook" {
  tags               = var.tags
  name               = "AWSGlueServiceSageMakerNotebookRole-${var.identifier_prefix}notebook"
  assume_role_policy = data.aws_iam_policy_document.notebook_assume_role.json
}