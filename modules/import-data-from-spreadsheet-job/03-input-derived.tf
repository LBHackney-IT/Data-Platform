locals {
  worksheet_key  = lower(replace(replace(trimspace(var.worksheet_name), ".", ""), " ", "-"))
  import_name    = "${var.department.identifier}-${local.worksheet_key}"
  s3_output_path = "s3://${var.raw_zone_bucket_id}/${var.department.identifier}/${var.output_folder_name}/${var.data_set_name}"
}
