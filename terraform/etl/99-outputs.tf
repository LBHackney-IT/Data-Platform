output "redshift_cluster_id" {
  value = try(module.redshift[0].cluster_id, "")
}

output "redshift_iam_role_arn" {
  value = try(module.redshift[0].role_arn, "")
}

output "redshift_schemas" {
  value     = local.redshift_schemas
  sensitive = true
}

output "redshift_users" {
  value     = local.redshift_users
  sensitive = true
}

output "redshift_roles" {
  value     = local.redshift_roles
  sensitive = true
}
