resource "aws_s3_bucket" "connector_bucket_dependencies" {
  bucket = "kafka-connector-bucket-dependencies"
  acl    = "private"

  tags = {
    Name        = "kafka-connector-bucket-dependencies"
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_object" "housing_repairs_dlo_cleaning_script" {
  bucket = aws_s3_bucket.connector_bucket_dependencies.id
  key    = "connector_dependencies/kafka_s3_connector.zip"
  acl    = "private"
  source = "../dependencies/kafka_s3_connector.zip"
  etag   = filemd5("../dependencies/kafka_s3_connector.zip")
}