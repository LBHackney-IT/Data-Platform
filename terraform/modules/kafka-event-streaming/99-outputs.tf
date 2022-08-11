output "schema_registry_url" {
  value = "http://${module.schema_registry.load_balancer_dns_name}:8081"
}

output "cluster_config" {
  value = {
    zookeeper_connect_string = aws_msk_cluster.kafka_cluster.zookeeper_connect_string
    bootstrap_brokers        = aws_msk_cluster.kafka_cluster.bootstrap_brokers
    bootstrap_brokers_tls    = aws_msk_cluster.kafka_cluster.bootstrap_brokers_tls
    vpc_security_groups      = [aws_security_group.kafka.id]
    vpc_subnets              = var.subnet_ids
    cluster_name             = aws_msk_cluster.kafka_cluster.cluster_name
    cluster_arn              = aws_msk_cluster.kafka_cluster.arn
    kms_key_arn              = aws_kms_key.kafka.arn
  }
}