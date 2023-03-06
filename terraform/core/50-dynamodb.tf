

module "watermarks_dynamodb_table" {
  source = "../modules/dynamodb"
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0

  name                           = "glue-watermarks"
  identifier_prefix              = local.short_identifier_prefix
  billing_mode                   = "PAY_PER_REQUEST"
  hash_key                       = "jobName"
  range_key                      = "runId"
  table_class                    = "STANDARD"
  point_in_time_recovery_enabled = true
  tags                           = merge(module.tags.values, { BackupPolicy = title(var.environment) })

  attributes = [
    {
      name = "jobName"
      type = "S"
    },
    {
      name = "runId"
      type = "S"
    }
  ]

  server_side_encryption_enabled = true
}



