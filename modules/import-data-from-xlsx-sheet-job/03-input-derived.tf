locals {
  worksheet_key  = lower(replace(trimspace(var.worksheet_name), " ", "-"))
  import_name    = "${var.department_folder_name}-${local.worksheet_key}"
  s3_output_path = "s3://${var.raw_zone_bucket_id}/${var.department_folder_name}/${var.output_folder_name}"
}
