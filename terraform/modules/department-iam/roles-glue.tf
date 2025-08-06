// =============================================================================
// GLUE AGENT ROLE
// =============================================================================

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

  name               = lower("${var.identifier_prefix}-glue-${var.department_identifier}")
  assume_role_policy = data.aws_iam_policy_document.glue_agent_assume_role.json
}

resource "aws_iam_role_policy_attachment" "glue_agent_s3_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_cloudwatch_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_scripts_and_athena_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.read_glue_scripts_and_mwaa_and_athena.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_secrets_manager_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_full_glue_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.full_glue_access.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_jdbc_connection_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.crawler_can_access_jdbc_connection.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_s3_glue_resources_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.full_s3_access_to_glue_resources.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_watermarks_table_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_access_to_watermarks_table.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_notebook_pass_role" {
  count      = var.environment == "prod" ? 0 : 1
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_runner_pass_role_to_glue_for_notebook_use.arn
}