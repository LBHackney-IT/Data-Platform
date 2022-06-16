data "aws_athena_workgroup" "department_workgroup" {
  name = "${var.short_identifier_prefix}${local.department_identifier}"
}