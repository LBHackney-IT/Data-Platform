output "zookeeper_connect_string" {
  value = aws_msk_cluster.hackit.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.hackit.bootstrap_brokers_tls
}