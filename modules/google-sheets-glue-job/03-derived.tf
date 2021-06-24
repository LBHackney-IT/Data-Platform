locals {
  dateset_name     = lower(replace(var.dateset_name, "_", "-"))
  full_output_path = "s3://${var.bucket_id}/${var.department_name}/${local.dateset_name}"
}