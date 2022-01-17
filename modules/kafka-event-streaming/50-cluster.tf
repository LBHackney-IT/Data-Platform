resource "aws_msk_cluster" "kafka_cluster" {
  cluster_name           = "${var.identifier_prefix}event-streaming"
  kafka_version          = "2.8.1"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.t3.small"
    ebs_volume_size = 1000
    client_subnets  = var.subnet_ids
    security_groups = [aws_security_group.kafka.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.kafka.arn
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

#  logging_info {
#    broker_logs {
#      cloudwatch_logs {
#        enabled   = true
#        log_group = aws_cloudwatch_log_group.mmh_log_group.name
#      }
#      firehose {
#        enabled         = true
#        delivery_stream = aws_kinesis_firehose_delivery_stream.mmh_delivery_logs_stream.name
#      }
#      s3 {
#        enabled = true
#        bucket  = aws_s3_bucket.bucket.id
#        prefix  = "logs/msk-"
#      }
#    }
#  }

  tags = var.tags
}