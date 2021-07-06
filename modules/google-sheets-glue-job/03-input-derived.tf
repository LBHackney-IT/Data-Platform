locals {
  dataset_name     = lower(replace(var.dataset_name, "_", "-"))
  import_name      = "${var.department_name}-${local.dataset_name}"
  full_output_path = "s3://${var.bucket_id}/${var.department_name}/${local.dataset_name}"
}