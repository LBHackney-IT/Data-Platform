resource "aws_sfn_state_machine" "step_function" {
  name       = "${var.identifier_prefix}${var.name}"
  role_arn   = var.role_arn
  definition = var.definition
  tags       = var.tags
}
