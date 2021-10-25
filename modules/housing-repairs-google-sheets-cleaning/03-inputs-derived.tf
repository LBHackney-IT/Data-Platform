locals {
  glue_job_name = "${var.short_identifier_prefix}Housing Repairs - ${title(replace(var.dataset_name, "-", " "))}"
}