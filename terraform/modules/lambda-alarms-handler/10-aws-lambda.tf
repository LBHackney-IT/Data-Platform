locals {
  lambda_name_underscore = replace(lower(var.lambda_name), "/[^a-zA-Z0-9]+/", "_")
  # This ensures that this data resource will not be evaluated until
  # after the null_resource has been created.
  lambda_exporter_id     = null_resource.run_install_requirements.id

  # This value gives us something to implicitly depend on
  # in the archive_file below.
  source_dir             = "../../lambdas/${local.lambda_name_underscore}"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
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
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.secrets_manager_kms_key.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}*"
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

#lambda
#packaging 
resource "null_resource" "run_install_requirements" {
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../../lambdas/${local.lambda_name_underscore}/*") : filesha1("${path.module}/${f}")]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "make install-requirements"
    working_dir = "${path.module}/../../../lambdas/${local.lambda_name_underscore}/"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = "../../lambdas/${local.lambda_name_underscore}.zip"
}

resource "aws_s3_object" "lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "${local.lambda_name_underscore}.zip"
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
  s3_key           = aws_s3_object.lambda.key
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = var.lambda_environment_variables
  }
}
