module "kafka_dependency_storage" {
  source            = "../s3-bucket"
  tags              = var.tags
  project           = var.project
  environment       = var.environment
  identifier_prefix = var.identifier_prefix
  bucket_name       = "Kafka Dependency Storage"
  bucket_identifier = "kafka-dependency-storage"
}

resource "aws_s3_bucket_object" "kafka_connector_s3" {
  bucket      = module.kafka_dependency_storage.bucket_id
  key         = "connectors/confluentinc-kafka-connect-s3-10.0.5.zip"
  acl         = "private"
  source      = ".${path.module}/connectors/confluentinc-kafka-connect-s3-10.0.5.zip"
  source_hash = filemd5("${path.module}/connectors/confluentinc-kafka-connect-s3-10.0.5.zip")
}