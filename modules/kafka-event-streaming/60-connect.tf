resource "aws_mskconnect_custom_plugin" "tenure_api" {
  content_type = "ZIP"
  name         = "${var.short_identifier_prefix}confluentinc-kafka-connect-s3-10-0-5-merged"
  description  = "A bundle consisting of the Confluentinc S3 Connect and Avro Deserializer"
  location {
    s3 {
      bucket_arn = module.kafka_dependency_storage.bucket_arn
      file_key   = aws_s3_bucket_object.kafka_connector_s3.key
    }
  }
}