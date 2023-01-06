module "dynamodb_table" {
  source = "../modules/dynamodb"
  count  = local.is_live_environment ? 1 : 0

  name                           = "glue-watermarks"
  billing_mode                   = "PAY_PER_REQUEST"
  hash_key                       = "jobName"
  range_key                      = "runId"
  table_class                    = "STANDARD"
  point_in_time_recovery_enabled = true
  tags = {
    "BackupPolicy" = var.environment == "prod" ? "Prod" : null
  }

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
}
