locals {
  #worksheet_key       = lower(replace(replace(trimspace(var.worksheet_name), ".", ""), " ", "-"))
  #import_name         = "${var.department.identifier}-${local.worksheet_key}"
  job_bookmark_option = var.enable_bookmarking ? "job-bookmark-enable" : "job-bookmark-disable"
}
