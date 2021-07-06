resource "aws_s3_bucket_object" "repairs_axis_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs-axis-cleaning.py"
  acl    = "private"
  source = "../scripts/repairs-axis-cleaning.py"
  etag   = filemd5("../scripts/repairs-axis-cleaning.py")
}

resource "aws_glue_job" "housing_repairs_axis_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Repairs Axis Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_axis_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-axis/cleaned"
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_axis"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_axis_cleaned_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-axis-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_axis_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-axis/cleaned/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}
