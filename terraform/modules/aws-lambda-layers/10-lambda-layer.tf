locals {
  lambda_name_underscore = replace(var.lambda_name, "-", "_")
  command                = "make all"
  environment_map        = var.environment_variables == null ? [] : [var.environment_variables]
}

resource "null_resource" "run_install_requirements" {
  count = var.install_requirements ? 1 : 0
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../../lambdas/${local.lambda_name_underscore}/*") : filesha1("${path.module}/${f}")]))
  }

  provisioner "local-exec" {
    # interpreter = ["bash", "-c"]
    command     = local.command
    working_dir = "${path.module}/../../../lambdas/${local.lambda_name_underscore}/"
  }
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = var.layer_zip_file
  source_code_hash    = fileexists("${path.module}/../../../lambdas/${local.lambda_name_underscore}/${var.layer_zip_file}") ? fileexists("${path.module}/../../../lambdas/${local.lambda_name_underscore}/${var.layer_zip_file}") : ""
  layer_name          = var.layer_name
  compatible_runtimes = var.compatible_runtimes
}
