Feature: S3

  @exclude_aws_s3_bucket.ssl_connection_resources\[0\]
  @exclude_module.qlik_server\[0\].aws_s3_bucket.qlik_alb_logs\[0\]
  @exclude_module.airflow.aws_s3_bucket.bucket
  @exclude_aws_s3_bucket.mwaa_bucket.aws_s3_bucket.bucket
  Scenario: Data must be encrypted at rest for buckets created using server_side_encryption_configuration property within bucket resource
    Given I have aws_s3_bucket defined
    Then it must have server_side_encryption_configuration

  @exclude_aws_s3_bucket.ssl_connection_resources\[0\]
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
  @exclude_module.liberator_dump_to_rds_snapshot\[0\].aws_s3_bucket.cloudtrail
  @exclude_module.liberator_db_snapshot_to_s3\[0\].module.rds_export_storage.aws_s3_bucket.bucket
  Scenario: Data must be encrypted at rest for buckets created using separate server side configuration resource
    Given I have aws_s3_bucket defined
    Then it must have aws_s3_bucket_server_side_encryption_configuration
