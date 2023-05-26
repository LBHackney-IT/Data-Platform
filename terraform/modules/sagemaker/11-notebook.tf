locals {
  glue_dev_endpoint_config = {
    endpoint_name             = "${var.identifier_prefix}sagemaker-development-endpoint-${var.instance_name}"
    extra_python_libs_s3_path = var.python_libs
    extra_jars_s3_path        = var.extra_jars
    worker_type               = "Standard"
    number_of_workers         = 2,
    role_arn                  = var.development_endpoint_role_arn
    public_key                = "${chomp(tls_private_key.dev_enpoint_key.public_key_openssh)} example@hackney.gov.uk\n"
  }
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "sagemaker_lifecycle" {
  name = "${var.identifier_prefix}sagemaker-lifecycle-configuration-${var.instance_name}"
  # on_start = base64encode(templatefile("${path.module}/scripts/notebook-start-up.sh",
  #   {
  #     "glueendpointconfig" : jsonencode(local.glue_dev_endpoint_config),
  #     "sparkmagicconfig" : file("${path.module}/spark-magic-config.json")
  #   }
  # ))
  on_start = base64encode("echo startup_script_temporarily_disabled")
}

resource "aws_sagemaker_notebook_instance" "nb" {
  name                    = "${var.identifier_prefix}sagemaker-notebook-${var.instance_name}"
  role_arn                = aws_iam_role.notebook.arn
  instance_type           = "ml.t3.medium"
  lifecycle_config_name   = aws_sagemaker_notebook_instance_lifecycle_configuration.sagemaker_lifecycle.name
  default_code_repository = var.github_repository
  platform_identifier     = "notebook-al1-v1"
  kms_key_id              = aws_kms_key.kms_key.key_id

  lifecycle {
    prevent_destroy = true
  }

  tags = merge({
    Name                  = "vehicle"
    aws-glue-dev-endpoint = local.glue_dev_endpoint_config.endpoint_name
  }, var.tags)
}

resource "aws_kms_key" "kms_key" {
  tags = var.tags

  description             = "${var.identifier_prefix} - sagemaker-notebook-${var.instance_name} KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}
