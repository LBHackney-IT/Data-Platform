output "zookeeper_connect_string" {
  value = aws_msk_cluster.mmh_streaming.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.mmh_streaming.bootstrap_brokers_tls
}