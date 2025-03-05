locals {
  dataset_name            = lower(replace(var.dataset_name, "_", "-"))
  import_name             = "${var.department.identifier}-${local.dataset_name}"
  full_output_path        = "s3://${var.bucket_id}/${var.department.identifier}/google-sheets/${local.dataset_name}"
  sheets_credentials_name = var.sheets_credentials_name == null ? var.department.google_service_account.credentials_secret.name : var.sheets_credentials_name
}