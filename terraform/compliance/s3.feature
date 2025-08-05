# buckets should only be excluded from one of these two rules
Feature: S3

  @exclude_aws_s3_bucket.ssl_connection_resources\[0\]
  @exclude_module.qlik_server\[0\].aws_s3_bucket.qlik_alb_logs\[0\]
  @exclude_module.airflow.aws_s3_bucket.bucket
  @exclude_aws_s3_bucket.mwaa_bucket
  @exclude_aws_s3_bucket.mwaa_etl_scripts_bucket
  @exclude_module.housing_nec_migration_storage.aws_s3_bucket.bucket
  @exclude_module.admin_bucket.aws_s3_bucket.bucket
  @exclude_module.cloudtrail_storage.aws_s3_bucket.bucket
  @exclude_module.file_sync_destination_nec.aws_s3_bucket.bucket
  @exclude_module.file_sync_destination_nec.aws_s3_bucket.log_bucket

  # This rule is in place for legacy buckets created with the deprecated block within the aws_s3_bucket resource
  Scenario: Data must be encrypted at rest for buckets created using server_side_encryption_configuration property within bucket resource
    Given I have aws_s3_bucket defined
    Then it must have server_side_encryption_configuration

  @exclude_aws_s3_bucket.ssl_connection_resources\[0\]
  @exclude_aws_s3_bucket.mwaa_bucket
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
  @exclude_module.kafka_event_streaming\[0\].module.kafka_dependency_storage.aws_s3_bucket.bucket
  @exclude_module.db_snapshot_to_s3\[0\].module.rds_export_storage.aws_s3_bucket.bucket
  @exclude_module.liberator_db_snapshot_to_s3\[0\].module.rds_export_storage.aws_s3_bucket.bucket
  # This rule checks for a separate sse block as supported by the s3 bucket module
  Scenario: Data must be encrypted at rest for buckets created using separate server side configuration resource
    Given I have aws_s3_bucket defined
    Then it must have aws_s3_bucket_server_side_encryption_configuration
