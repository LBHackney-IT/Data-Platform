# Staging-only SQL Server network access from Data and Insight ECS.
# This ECS role will be used to read from RDS and write to S3 to meet the migration requirements.
# Uses the shared locals and RDS module in 66-blackbaud-restore.tf.

data "aws_security_group" "blackbaud_ecs" {
  count = local.blackbaud_migration_enabled ? 1 : 0

  filter {
    name   = "group-name"
    values = ["dap-ecs-ecs-sg-data-and-insight-${var.environment}"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.aws_vpc_id.value]
  }
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

# ECS discovers the RDS endpoint and reads its RDS-managed administrator secret
# to submit native restores.
resource "aws_iam_role_policy" "blackbaud_ecs_restore" {
  count = local.blackbaud_migration_enabled ? 1 : 0
  name  = "${local.blackbaud_migration_name}-ecs-restore"
  role  = "${local.identifier_prefix}-data-and-insight-ecs-task-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["rds:DescribeDBInstances"]
        Resource = module.blackbaud_migration_rds[0].db_instance_arn
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = module.blackbaud_migration_rds[0].db_instance_master_user_secret_arn
      }
    ]
  })
}
