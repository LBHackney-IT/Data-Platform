locals {
  lambda_name_underscore = replace(var.lambda_name, "-", "_")
  command                = var.runtime == "python3.8" ? "make install-requirements" : (var.runtime == "nodejs14.x" ? "npm install" : 0)

}

resource "aws_lambda_function" "lambda" {
  function_name    = lower("${var.identifier_prefix}${var.lambda_name}")
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = var.s3_key
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  environment {
    variables = var.environment_variables
  }
  ephemeral_storage {
    size = var.ephemeral_storage
  }
  tags = var.tags
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = var.lambda_output_path
}

resource "null_resource" "run_install_requirements" {
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../../lambdas/${local.lambda_name_underscore}/*") : filesha1("${path.module}/${f}")]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.command
    working_dir = "${path.module}/../../../lambdas/${local.lambda_name_underscore}/"
  }
}

resource "aws_s3_bucket_object" "lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "${local.lambda_name_underscore}.zip"
  source      = data.archive_file.lambda.output_path
  acl         = "private"
  source_hash = null_resource.run_install_requirements.triggers["dir_sha1"]
}
