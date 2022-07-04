moved {
  from = aws_s3_bucket_object.convertbng
  to   = aws_s3_object.convertbng
}
moved {
  from = aws_s3_bucket_object.copy_json_data_landing_to_raw
  to   = aws_s3_object.copy_json_data_landing_to_raw
}
moved {
  from = aws_s3_bucket_object.copy_tables_landing_to_raw
  to   = aws_s3_object.copy_tables_landing_to_raw
}
moved {
  from = aws_s3_bucket_object.dynamodb_tables_ingest
  to   = aws_s3_object.dynamodb_tables_ingest
}
moved {
  from = aws_s3_bucket_object.helpers
  to   = aws_s3_object.helpers
}
moved {
  from = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection
  to   = aws_s3_object.ingest_database_tables_via_jdbc_connection
}
moved {
  from = aws_s3_bucket_object.jars
  to   = aws_s3_object.jars
}
moved {
  from = aws_s3_bucket_object.liberator_prod_to_pre_prod
  to   = aws_s3_object.liberator_prod_to_pre_prod
}
moved {
  from = aws_s3_bucket_object.pydeequ
  to   = aws_s3_object.pydeequ
}
moved {
  from = aws_s3_bucket_object.shutdown_notebooks
  to   = aws_s3_object.shutdown_notebooks
}
moved {
  from = module.icaseworks_api_ingestion[0].aws_s3_bucket_object.lambda
  to   = module.icaseworks_api_ingestion[0].aws_s3_object.lambda
}
moved {
  from = module.kafka_event_streaming[0].aws_s3_bucket_object.kafka_connector_s3
  to   = module.kafka_event_streaming[0].aws_s3_object.kafka_connector_s3
}
moved {
  from = module.liberator_db_snapshot_to_s3[0].aws_s3_bucket_object.rds_snapshot_to_s3_lambda
  to   = module.liberator_db_snapshot_to_s3[0].aws_s3_object.rds_snapshot_to_s3_lambda
}
moved {
  from = module.liberator_db_snapshot_to_s3[0].aws_s3_bucket_object.s3_to_s3_copier_lambda
  to   = module.liberator_db_snapshot_to_s3[0].aws_s3_object.s3_to_s3_copier_lambda
}
moved {
  from = module.set_budget_limit_amount.aws_s3_bucket_object.set_budget_limit_amount_lambda
  to   = module.set_budget_limit_amount.aws_s3_object.set_budget_limit_amount_lambda
}