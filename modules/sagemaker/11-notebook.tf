resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "sagemaker_lifecycle" {
  name = "${var.identifier_prefix}sagemaker-lifecycle-configuration"
  on_create = base64encode(templatefile("${path.module}/scripts/notebook-start-up.sh",
    {
      "glueendpoint" : aws_glue_dev_endpoint.glue_endpoint.name,
      "sparkmagicconfig" : file("${path.module}/spark-magic-config.json")
    }
  ))

  on_start = base64encode(templatefile("${path.module}/scripts/notebook-start-up.sh",
    {
      "glueendpoint" : aws_glue_dev_endpoint.glue_endpoint.name,
      "sparkmagicconfig" : file("${path.module}/spark-magic-config.json")
    }
  ))
}


resource "aws_sagemaker_code_repository" "data_platform" {
  code_repository_name = "data-platform-notebooks"

  git_config {
    repository_url = "https://github.com/LBHackney-IT/Data-Platform-Notebooks.git"
  }
}

resource "aws_sagemaker_notebook_instance" "nb" {
  name                    = "${var.identifier_prefix}sagemaker-notebook"
  role_arn                = aws_iam_role.notebook.arn
  instance_type           = "ml.t3.medium"
  lifecycle_config_name   = aws_sagemaker_notebook_instance_lifecycle_configuration.sagemaker_lifecycle.name
  default_code_repository = aws_sagemaker_code_repository.data_platform.code_repository_name

  tags = merge({
    Name                  = "vehicle"
    aws-glue-dev-endpoint = aws_glue_dev_endpoint.glue_endpoint.name
  }, var.tags)
}
