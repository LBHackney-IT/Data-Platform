# Staging-only SQL Server network access from Data and Insight ECS.
# This ECS role will be used to read from RDS and write to S3 to meet the migration requirements.
# Uses the shared locals and RDS module in 66-blackbaud-restore.tf.

data "aws_secretsmanager_secret_version" "blackbaud_ecs_security_groups" {
  count     = local.blackbaud_migration_enabled ? 1 : 0
  secret_id = "airflow/variables/ecs_task_security_groups_mapping"
}

data "aws_security_group" "blackbaud_ecs" {
  count = local.blackbaud_migration_enabled ? 1 : 0
  id = nonsensitive(
    jsondecode(data.aws_secretsmanager_secret_version.blackbaud_ecs_security_groups[0].secret_string)["data-and-insight"]
  )
}

resource "aws_security_group_rule" "blackbaud_from_ecs" {
  count                    = local.blackbaud_migration_enabled ? 1 : 0
  type                     = "ingress"
  description              = "SQL Server access from Data and Insight ECS"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.blackbaud_ecs[0].id
  security_group_id        = module.blackbaud_migration_rds[0].db_security_group_id
}
