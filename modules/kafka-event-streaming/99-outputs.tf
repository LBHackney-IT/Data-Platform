output "default_s3_plugin_configuration" {
  value = {
    connect_version               = "2.7.1"
    service_execution_role_arn    = aws_iam_role.kafka_connector.arn
    connector_log_delivery_config = {
      log_group_enabled = true,
      log_group         = aws_cloudwatch_log_group.connector_log_group.name
    }
    capacity = {
      "auto_scaling" = {
        "maxWorkerCount" = 3,
        "mcuCount"       = 1,
        "minWorkerCount" = 1,
        "scaleInPolicy"  = {
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
      "connector.class"                     = "io.confluent.connect.s3.S3SinkConnector"
      "flush.size"                          = 1
      "tasks.max"                           = 2
      "topics"                              = "tenure_api"
      "s3.bucket.name"                      = var.s3_bucket_to_write_to.bucket_id
      "s3.sse.kms.key.id"                   = var.s3_bucket_to_write_to.kms_key_id
      "s3.region"                           = "eu-west-2"
      "key.converter"                       = "org.apache.kafka.connect.storage.StringConverter"
      "key.converter.schemas.enable"        = false
      "value.converter"                     = "io.confluent.connect.avro.AvroConverter"
      "value.converter.schema.registry.url" = "http://${module.schema_registry.load_balancer_dns_name}:8081"
      "value.converter.schemas.enable"      = true
      "storage.class"                       = "io.confluent.connect.s3.storage.S3Storage"
      "format.class"                        = "io.confluent.connect.s3.format.parquet.ParquetFormat"
      "partitioner.class"                   = "io.confluent.connect.storage.partitioner.DefaultPartitioner"
      "schema.compatibility"                = "BACKWARD"
      "errors.log.enable"                   = true
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
