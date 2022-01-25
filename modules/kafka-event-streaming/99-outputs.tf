output "default_s3_plugin_configuration" {
    value = {
        connect_version = "2.8.1"
        service_execution_role_arn = aws_iam_role.kafka_connector.arn
        connector_log_delivery_config = {
            log_group_enabled = true,
            log_group = aws_cloudwatch_log_group.connector_log_group.name
        }
        capacity = {
            "autoScaling" =  {
                "maxWorkerCount"= 3,
                "mcuCount"= 1,
                "minWorkerCount"= 1,
                "scaleInPolicy"= {
                    "cpuUtilizationPercentage"= 20
                },
                "scaleOutPolicy"= {
                    "cpuUtilizationPercentage"= 80
                }
            }
        },
        connector_s3_plugin = {
            bucket_arn = module.kafka_dependency_storage.bucket_arn
            file_key = aws_s3_bucket_object.kafka_connector_s3.key
            version = aws_s3_bucket_object.kafka_connector_s3.version_id
            name = "confluentinc-kafka-connect-s3-10.0.5"
        }
        connector_configuration = {
            "connector.class"="io.confluent.connect.s3.S3SinkConnector"
            "tasks.max"=2
            "format.class"="io.confluent.connect.s3.format.avro.AvroFormat"
            "flush.size"=10
            "enhanced.avro.schema.support"=true
            "schema.compatibility"="BACKWARD"
            "s3.region"="eu-west-2"
            "s3.bucket.name"=var.bucket_name
            "s3.sse.kms.key.id"= var.kms_key_id
        }
    }
}

output "cluster_config" {
    type = object
    value = {
        zookeeper_connect_string = aws_msk_cluster.kafka_cluster.zookeeper_connect_string
        bootstrap_brokers = aws_msk_cluster.kafka_cluster.bootstrap_brokers
        bootstrap_brokers_tls = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls
        vpc_security_groups = [aws_security_group.kafka.id]
        vpc_subnets = var.subnet_ids
    }
}

# Topic specific connector config

output "tenure_connector_name" {
    value = "tenure-changes"
}
