output "role_arn" {
  value = aws_iam_role.redshift_role.arn
}

output "cluster_id" {
  value = aws_redshift_cluster.redshift_cluster.cluster_identifier
}

output "cluster_arn" {
  value = aws_redshift_cluster.redshift_cluster.arn
}
