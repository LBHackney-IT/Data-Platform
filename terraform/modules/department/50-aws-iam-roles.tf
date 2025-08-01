// User Role for staging account - This role is a combination of policies ready to be applied to SSO
data "aws_iam_policy_document" "sso_staging_user_policy" {
  override_policy_documents = local.create_notebook ? [
    data.aws_iam_policy_document.s3_department_access.json,
    data.aws_iam_policy_document.glue_access.json,
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.redshift_department_read_access.json,
    data.aws_iam_policy_document.notebook_access[0].json
    ] : [
    data.aws_iam_policy_document.s3_department_access.json,
    data.aws_iam_policy_document.glue_access.json,
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.redshift_department_read_access.json,
    data.aws_iam_policy_document.mwaa_department_web_server_access.json
  ]
}

// User Role for production account - This role is a combination of policies ready to be applied to SSO
data "aws_iam_policy_document" "sso_production_user_policy" {
  override_policy_documents = [
    data.aws_iam_policy_document.read_only_s3_department_access.json,
    data.aws_iam_policy_document.read_only_glue_access.json,
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.athena_can_write_to_s3.json
  ]
}

// Glue role + attachments
data "aws_iam_policy_document" "glue_agent_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "glue_agent" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-glue-${local.department_identifier}")
  assume_role_policy = data.aws_iam_policy_document.glue_agent_assume_role.json
}


resource "aws_iam_role_policy_attachment" "glue_agent_s3_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "glue_agents_secrets_manager_read_only" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "read_glue_scripts_and_mwaa_and_athena" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.read_glue_scripts_and_mwaa_and_athena.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_glue_can_write_to_cloudwatch" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_glue_full_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.full_glue_access.arn
}

resource "aws_iam_role_policy_attachment" "crawler_can_access_jdbc_connection" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.crawler_can_access_jdbc_connection.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_has_full_s3_access_to_glue_resources" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.full_s3_access_to_glue_resources.arn
}

resource "aws_iam_role_policy_attachment" "glue_access_to_watermarks_table" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_access_to_watermarks_table.arn
}

resource "aws_iam_role_policy_attachment" "glue_runner_pass_role_to_glue_for_notebook_use" {
  count      = var.environment == "prod" ? 0 : 1
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_runner_pass_role_to_glue_for_notebook_use.arn
}

# Define a map for the departmental airflow policies
locals {
  airflow_policy_map = {
    s3_access                 = aws_iam_policy.s3_access.arn,
    secrets_manager_read_only = aws_iam_policy.secrets_manager_read_only.arn,
    airflow_base_policy       = aws_iam_policy.airflow_base_policy.arn,
    department_ecs_passrole   = aws_iam_policy.department_ecs_passrole.arn
  }
}

# IAM user and permission for departmetnal airflow user
resource "aws_iam_user" "airflow_user" {
  count = var.departmental_airflow_user ? 1 : 0
  name  = "${local.department_identifier}-airflow-user"
  tags  = var.tags
}

resource "aws_iam_user_policy_attachment" "airflow_user_policy_attachment" {
  for_each   = var.departmental_airflow_user ? local.airflow_policy_map : {}
  user       = aws_iam_user.airflow_user[0].name
  policy_arn = each.value
}

resource "aws_iam_access_key" "airflow_user_key" {
  count = var.departmental_airflow_user ? 1 : 0
  user  = aws_iam_user.airflow_user[0].name
}

# Store airflow user credentials in Secrets Manager with required format
resource "aws_secretsmanager_secret" "airflow_user_secret" {
  count = var.departmental_airflow_user ? 1 : 0
  name  = "airflow/connections/${local.department_identifier}-airflow-aws-default"
}

resource "aws_secretsmanager_secret_version" "airflow_user_secret_version" {
  count     = var.departmental_airflow_user ? 1 : 0
  secret_id = aws_secretsmanager_secret.airflow_user_secret[0].id
  secret_string = jsonencode({
    conn_type = "aws",
    login     = aws_iam_access_key.airflow_user_key[0].id,
    password  = aws_iam_access_key.airflow_user_key[0].secret,
    extra     = jsonencode({ region_name = var.region })
  })
}

# Department ECS
resource "aws_iam_role" "department_ecs_role" {
  name               = lower("${var.identifier_prefix}-${local.department_identifier}-ecs-task-role")
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "department_ecs_policy" {
  role       = aws_iam_role.department_ecs_role.name
  policy_arn = aws_iam_policy.department_ecs_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_access_attachment_to_ecs_role" {
  role       = aws_iam_role.department_ecs_role.name
  policy_arn = aws_iam_policy.glue_access.arn
}

resource "aws_iam_role_policy" "grant_s3_access_to_ecs_role" {
  role   = aws_iam_role.department_ecs_role.name
  policy = data.aws_iam_policy_document.s3_department_access.json
}

resource "aws_iam_role_policy_attachment" "mtfh_access_attachment" {
  count      = contains(["data-and-insight", "housing"], local.department_identifier) ? 1 : 0
  role       = aws_iam_role.department_ecs_role.name
  policy_arn = aws_iam_policy.mtfh_access_policy[0].arn
}
