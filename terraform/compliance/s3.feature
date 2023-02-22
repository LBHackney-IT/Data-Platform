Feature: S3

  @exclude_aws_s3_bucket.ssl_connection_resources\[0\]
  Scenario: Data must be encrypted at rest for buckets created using server_side_encryption_configuration property within bucket resource
    Given I have aws_s3_bucket defined
    Then it must have server_side_encryption_configuration

  @exclude_module.athena_storage.aws_s3_bucket.bucket
  @exclude_module.glue_scripts.aws_s3_bucket.bucket
  @exclude_module.glue_temp_storage.aws_s3_bucket.bucket
  @exclude_module.lambda_artefact_storage.aws_s3_bucket.bucket
  @exclude_module.lambda_artefact_storage_for_api_account.aws_s3_bucket.bucket
  @exclude_module.landing_zone.aws_s3_bucket.bucket
  @exclude_module.liberator_data_storage.aws_s3_bucket.bucket
  @exclude_module.noiseworks_data_storage.aws_s3_bucket.bucket
  @exclude_module.raw_zone.aws_s3_bucket.bucket
  @exclude_module.refined_zone.aws_s3_bucket.bucket
  @exclude_module.spark_ui_output_storage.aws_s3_bucket.bucket
  @exclude_module.trusted_zone.aws_s3_bucket.bucket
  Scenario: Data must be encrypted at rest for buckets created using separate server side configuration resource
    Given I have aws_s3_bucket defined
    Then it must have aws_s3_bucket_server_side_encryption_configuration
