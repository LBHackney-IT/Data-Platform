// =============================================================================
// DEPARTMENTAL AIRFLOW USER
// =============================================================================

# Define a map for the departmental airflow policies
locals {
  airflow_policy_map = {
    s3_access                 = aws_iam_policy.s3_access.arn,
    secrets_manager_read_only = aws_iam_policy.secrets_manager_read_only.arn,
    airflow_base_policy       = aws_iam_policy.airflow_base_policy.arn,
    department_ecs_passrole   = aws_iam_policy.department_ecs_passrole.arn
  }
}

# IAM user and permission for departmental airflow user
resource "aws_iam_user" "airflow_user" {
  count = var.create_airflow_user ? 1 : 0
  name  = "${var.department_identifier}-airflow-user"
  tags  = var.tags
}

resource "aws_iam_user_policy_attachment" "airflow_user_policy_attachment" {
  for_each   = var.create_airflow_user ? local.airflow_policy_map : {}
  user       = aws_iam_user.airflow_user[0].name
  policy_arn = each.value
}

resource "aws_iam_access_key" "airflow_user_key" {
  count = var.create_airflow_user ? 1 : 0
  user  = aws_iam_user.airflow_user[0].name
}

# Store airflow user credentials in Secrets Manager with required format
resource "aws_secretsmanager_secret" "airflow_user_secret" {
  count = var.create_airflow_user ? 1 : 0
  name  = "airflow/connections/${var.department_identifier}-airflow-aws-default"
  tags  = var.tags
}

resource "aws_secretsmanager_secret_version" "airflow_user_secret_version" {
  count     = var.create_airflow_user ? 1 : 0
  secret_id = aws_secretsmanager_secret.airflow_user_secret[0].id
  secret_string = jsonencode({
    conn_type = "aws",
    login     = aws_iam_access_key.airflow_user_key[0].id,
    password  = aws_iam_access_key.airflow_user_key[0].secret,
    extra     = jsonencode({ region_name = var.region })
  })
}