module "sagemaker" {
  source                        = "../modules/sagemaker/"
  development_endpoint_role_arn = aws_iam_role.glue_role.arn
  tags                          = module.tags.values
  identifier_prefix             = local.short_identifier_prefix
  python_libs                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.pydeequ.key}"
  extra_jars                    = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.jars.key}"
}