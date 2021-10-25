locals {
  glue_job_name  = "${var.short_identifier_prefix}Housing Repairs - ${title(replace(var.dataset_name, "-", " "))}"
  extra_py_files = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key}"
}