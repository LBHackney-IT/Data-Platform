locals {
  lambda_name_underscore = replace(var.lambda_name, "-", "_")
  command                = "make install-requirements"
  environment_map        = var.environment_variables == null ? [] : [var.environment_variables]
}

resource "aws_lambda_function" "lambda" {
  function_name    = lower("${var.identifier_prefix}${var.lambda_name}")
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = data.archive_file.lambda.output_base64sha256
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = var.s3_key
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  dynamic "environment" {
    for_each = local.environment_map
    content {
      variables = environment.value
    }
  }

  ephemeral_storage {
    size = var.ephemeral_storage
  }
  tags = var.tags

  depends_on = [null_resource.run_install_requirements[0], data.archive_file.lambda]
}

data "archive_file" "lambda" {
  type             = "zip"
  source_dir       = var.lambda_source_dir
  output_path      = var.lambda_output_path
  depends_on       = [null_resource.run_install_requirements[0]]
  output_file_mode = var.output_file_mode
}

resource "null_resource" "run_install_requirements" {
  count = var.install_requirements ? 1 : 0
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../../lambdas/${local.lambda_name_underscore}/*") : filesha1("${path.module}/${f}")]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.command
    working_dir = "${path.module}/../../../lambdas/${local.lambda_name_underscore}/"
  }
}

resource "aws_s3_object" "lambda" {
  bucket     = var.lambda_artefact_storage_bucket
  key        = "${local.lambda_name_underscore}.zip"
  source     = data.archive_file.lambda.output_path
  acl        = "private"
  depends_on = [data.archive_file.lambda]
}