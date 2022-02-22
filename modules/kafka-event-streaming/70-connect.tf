resource "aws_mskconnect_custom_plugin" "tenure_api" {
  content_type = "ZIP"
  name = "${var.identifier_prefix}confluentinc-kafka-connect-s3-10-0-5"
  location {
    s3 {
      bucket_arn = module.kafka_dependency_storage.bucket_arn
      file_key   = aws_s3_bucket_object.kafka_connector_s3.key
    }
  }
}