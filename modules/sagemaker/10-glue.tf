resource "aws_glue_dev_endpoint" "glue_endpoint" {
  name         = "${var.identifier_prefix}sagemaker-development-endpoint"
  role_arn     = var.development_endpoint_role_arn
  glue_version = "1.0"
  # number_of_workers         = "2" Only available when using worker type G.1X & G.2X
  worker_type               = "Standard"
  arguments                 = { "--enable-glue-datacatalog" : "true", "GLUE_PYTHON_VERSION" : "3" }
  extra_python_libs_s3_path = var.python_libs
  extra_jars_s3_path        = var.extra_jars
}