output "default_s3_plugin_configuration" {
  value = {
    connect_version            = "2.7.1"
    service_execution_role_arn = aws_iam_role.kafka_connector.arn
    connector_log_delivery_config = {
      log_group_enabled = true,
      log_group         = aws_cloudwatch_log_group.connector_log_group.name
    }
    capacity = {
      "auto_scaling" = {
        "maxWorkerCount" = 3,
        "mcuCount"       = 1,
        "minWorkerCount" = 1,
        "scaleInPolicy" = {
          "cpuUtilizationPercentage" = 20
        },
        "scaleOutPolicy" = {
          "cpuUtilizationPercentage" = 80
        }
      }
    },
    connector_s3_plugin = {
      bucket_arn = module.kafka_dependency_storage.bucket_arn
      file_key   = aws_s3_bucket_object.kafka_connector_s3.key
      name       = "kafka-connect-s3-with-aws-glue-schema-registry"
    }
    connector_configuration = {
      "flush.size"           = "1"
      "tasks.max"            = "2"
      "connector.class"      = "io.confluent.connect.s3.S3SinkConnector"
      "s3.region"            = "eu-west-2"
      "s3.bucket.name"       = var.s3_bucket_to_write_to.bucket_id
      "s3.sse.kms.key.id"    = var.s3_bucket_to_write_to.kms_key_id
      "format.class"         = "io.confluent.connect.s3.format.parquet.ParquetFormat"
      "topics"               = "tenure-api"
      "schema.compatibility" = "BACKWARD"
      "partitioner.class"    = "io.confluent.connect.storage.partitioner.DefaultPartitioner"
      "storage.class"        = "io.confluent.connect.s3.storage.S3Storage"

      "value.converter.schemaAutoRegistrationEnabled" = "true"
      "value.converter.avroRecordType"                = "GENERIC_RECORD"
      "value.converter"                               = "com.amazonaws.services.schemaregistry.kafkaconnect.AWSKafkaAvroConverter"
      "value.converter.schemaName"                    = var.aws_glue_schema.schema_name
      "value.converter.registry.name"                 = var.aws_glue_registry.registry_name
      "value.converter.region"                        = "eu-west-2"
      "value.converter.schemas.enable"                = "true"
      "key.converter"                                 = "org.apache.kafka.connect.storage.StringConverter"
    }
  }
}

output "cluster_config" {
  value = {
    zookeeper_connect_string = aws_msk_cluster.kafka_cluster.zookeeper_connect_string
    bootstrap_brokers        = aws_msk_cluster.kafka_cluster.bootstrap_brokers
    bootstrap_brokers_tls    = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls
    vpc_security_groups      = [aws_security_group.kafka.id]
    vpc_subnets              = var.subnet_ids
  }
}

# Topic specific connector config

output "tenure_connector_name" {
  value = "tenure-changes"
}
