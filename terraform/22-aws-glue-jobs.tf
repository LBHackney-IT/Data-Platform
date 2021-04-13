module "test_data" {
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = aws_s3_bucket.glue_scripts_bucket.id
  glue_temp_storage_bucket_id     = aws_s3_bucket.glue_temp_storage_bucket.id
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Test"
  google_sheets_document_id       = "1yKAxzUGeGJulFEcVBxatow3jUdTeqfzGvvCgdshiN5g"
  google_sheets_worksheet_name    = "Sheet1"
  department_folder_name          = "test"
  output_folder_name              = "test1"
  enable_glue_trigger             = false
}

module "housing_repair_data" {
  source                          = "../modules/google-sheets-glue-job"
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id          = aws_s3_bucket.glue_scripts_bucket.id
  glue_temp_storage_bucket_id     = aws_s3_bucket.glue_temp_storage_bucket.id
  google_sheets_import_script_key = aws_s3_bucket_object.google_sheets_import_script.key
  landing_zone_bucket_id          = module.landing_zone.bucket_id
  sheets_credentials_name         = aws_secretsmanager_secret.sheets_credentials_housing.name
  tags                            = module.tags.values
  glue_job_name                   = "Repair Orders"
  google_sheets_document_id       = "1i9q42Kkbugwi4f2S4zdyid2ZjoN1XLjuYvqYqfHyygs"
  google_sheets_worksheet_name    = "Form responses 1"
  department_folder_name          = local.departments.housing.s3_read_write_directory
  output_folder_name              = "repair-orders"
}

resource "aws_glue_security_configuration" "glue_job_security_configuration_to_raw" {
  name = "glue-job-security-configuration-to-raw"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = module.raw_zone.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}

resource "aws_glue_job" "glue_job_template" {
  tags = module.tags.values

  name              = "Glue job template"
  number_of_workers = 10
  worker_type       = "G.2X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.raw_zone.bucket_id}/glue-job-template-script-to-raw.py"
  }

  glue_version = "2.0"
  security_configuration = aws_glue_security_configuration.glue_job_security_configuration_to_raw.name
}
