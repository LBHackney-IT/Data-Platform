data "aws_caller_identity" "current" {}

data "aws_lambda_layer_version" "google_apis_layer" {
  layer_name = "google-apis-layer"
}

data "aws_lambda_layer_version" "urllib3_layer" {
  layer_name = "urllib3-1-26-18-layer"
}

locals {
  lambda_timeout     = 900
  lambda_memory_size = 3072
}
