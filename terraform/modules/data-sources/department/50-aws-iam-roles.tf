data "aws_iam_role" "glue_agent" {
  name = lower("${var.identifier_prefix}-glue-${local.department_identifier}")
}