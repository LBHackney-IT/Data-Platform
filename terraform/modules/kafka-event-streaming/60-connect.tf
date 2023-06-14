resource "aws_mskconnect_custom_plugin" "avro_converter_s3_sink" {
  content_type = "ZIP"
  name         = "${var.short_identifier_prefix}confluentinc-kafka-connect-s3-10-0-5-merged"
  description  = "A bundle consisting of the Confluentinc S3 Connect and Avro Deserializer"
  location {
    s3 {
      bucket_arn = module.kafka_dependency_storage.bucket_arn
      file_key   = aws_s3_object.kafka_connector_s3.key
    }
  }
}


locals {
  topics = [
    "tenure_api",
    "contact_details_api"
  ]
}

resource "aws_mskconnect_connector" "topics" {
  for_each    = toset(local.topics)
  name        = replace(lower("${var.short_identifier_prefix}${each.value}"), "/[^a-zA-Z0-9]+/", "-")
  description = "Kafka connector to write ${each.value} events to S3"

  kafkaconnect_version = "2.7.1"

  capacity {
    autoscaling {
      mcu_count        = 1
      min_worker_count = 1
      max_worker_count = 2

      scale_in_policy {
        cpu_utilization_percentage = 20
      }

      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  connector_configuration = {
    "connector.class"                     = "io.confluent.connect.s3.S3SinkConnector"
    "flush.size"                          = "1"
    "tasks.max"                           = "2"
    "topics"                              = each.value
    "topics.dir"                          = "event-streaming"
    "s3.bucket.name"                      = var.s3_bucket_to_write_to.bucket_id
    "s3.sse.kms.key.id"                   = var.s3_bucket_to_write_to.kms_key_id
    "s3.region"                           = "eu-west-2"
    "key.converter"                       = "org.apache.kafka.connect.storage.StringConverter"
    "key.converter.schemas.enable"        = "False"
    "value.converter"                     = "io.confluent.connect.avro.AvroConverter"
    "value.converter.schema.registry.url" = "http://${module.schema_registry.load_balancer_dns_name}:8081"
    "value.converter.schemas.enable"      = "True"
    "storage.class"                       = "io.confluent.connect.s3.storage.S3Storage"
    "format.class"                        = "io.confluent.connect.s3.format.parquet.ParquetFormat"
    "schema.compatibility"                = "BACKWARD"
    "errors.log.enable"                   = "True"
    "partitioner.class"                   = "io.confluent.connect.storage.partitioner.TimeBasedPartitioner"
    "path.format"                         = "'import_year'=YYYY/'import_month'=MM/'import_day'=dd/'import_date'=YYYYMMdd"
    "locale"                              = "en-GB"
    "timezone"                            = "UTC"
    "partition.duration.ms"               = "86400000"

  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls

      vpc {
        security_groups = [aws_security_group.kafka.id]
        subnets         = var.subnet_ids
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "NONE"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.avro_converter_s3_sink.arn
      revision = aws_mskconnect_custom_plugin.avro_converter_s3_sink.latest_revision
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        log_group = aws_cloudwatch_log_group.connector_log_group.name
        enabled   = true
      }
    }
  }

  service_execution_role_arn = aws_iam_role.kafka_connector.arn
}