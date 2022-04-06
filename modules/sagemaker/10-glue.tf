resource "tls_private_key" "dev_enpoint_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "dev_enpoint_key" {
  tags = var.tags

  name        = "/${var.identifier_prefix}glue-dev-endpoint"
  type        = "SecureString"
  description = "The private key for the glue development endpoint"
  value       = tls_private_key.dev_enpoint_key.private_key_pem
}

resource "aws_glue_dev_endpoint" "glue_endpoint" {
  name                      = "${var.identifier_prefix}sagemaker-development-endpoint"
  role_arn                  = var.development_endpoint_role_arn
  glue_version              = "1.0"
  number_of_workers         = "2"
  worker_type               = "Standard"
  arguments                 = { "--enable-glue-datacatalog" : "true", "GLUE_PYTHON_VERSION" : "3" }
  extra_python_libs_s3_path = var.python_libs
  extra_jars_s3_path        = var.extra_jars
  public_keys               = ["${chomp(tls_private_key.dev_enpoint_key.public_key_openssh)} emma.corbett@hackney.gov.uk\n"]
}

