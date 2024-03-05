module "lambda_layer_1" {
  count               = local.is_live_environment ? 1 : 0
  source              = "../modules/aws-lambda-layers/"
  lambda_name         = "lambda_layers"
  tags                = module.tags.values
  identifier_prefix   = local.short_identifier_prefix
  layer_zip_file      = "layer1.zip"
  layer_name          = "panas-2-1-4-layer"
  compatible_runtimes = ["python3.9"]
}

module "lambda_layer_2" {
  count               = local.is_live_environment ? 1 : 0
  source              = "../modules/aws-lambda-layers/"
  lambda_name         = "lambda_layers"
  tags                = module.tags.values
  identifier_prefix   = local.short_identifier_prefix
  layer_zip_file      = "layer2.zip"
  layer_name          = "requests-2-31-0-and-httplib-0-22-0-layer"
  compatible_runtimes = ["python3.9"]
}

module "lambda_layer_3" {
  count               = local.is_live_environment ? 1 : 0
  source              = "../modules/aws-lambda-layers/"
  lambda_name         = "lambda_layers"
  tags                = module.tags.values
  identifier_prefix   = local.short_identifier_prefix
  layer_zip_file      = "layer3.zip"
  layer_name          = "notifications-python-client-9-0-0-layer"
  compatible_runtimes = ["python3.9"]
}

module "lambda_layer_4" {
  count               = local.is_live_environment ? 1 : 0
  source              = "../modules/aws-lambda-layers/"
  lambda_name         = "lambda_layers"
  tags                = module.tags.values
  identifier_prefix   = local.short_identifier_prefix
  layer_zip_file      = "layer4.zip"
  layer_name          = "numpy-1-26-3-layer"
  compatible_runtimes = ["python3.9"]
}

module "lambda_layer_5" {
  count               = local.is_live_environment ? 1 : 0
  source              = "../modules/aws-lambda-layers/"
  lambda_name         = "lambda_layers"
  tags                = module.tags.values
  identifier_prefix   = local.short_identifier_prefix
  layer_zip_file      = "layer5.zip"
  layer_name          = "google-apis-layer"
  compatible_runtimes = ["python3.9"]
}

module "lambda_layer_6" {
  count               = local.is_live_environment ? 1 : 0
  source              = "../modules/aws-lambda-layers/"
  lambda_name         = "lambda_layers"
  tags                = module.tags.values
  identifier_prefix   = local.short_identifier_prefix
  layer_zip_file      = "layer6.zip"
  layer_name          = "urllib3-1-26-18-layer"
  compatible_runtimes = ["python3.9"]
}

module "lambda_layer_7" {
  count               = local.is_live_environment ? 1 : 0
  source              = "../modules/aws-lambda-layers/"
  lambda_name         = "lambda_layers"
  tags                = module.tags.values
  identifier_prefix   = local.short_identifier_prefix
  layer_zip_file      = "layer7.zip"
  layer_name          = "s3fs-2023-12-2-layer"
  compatible_runtimes = ["python3.9"]
}
