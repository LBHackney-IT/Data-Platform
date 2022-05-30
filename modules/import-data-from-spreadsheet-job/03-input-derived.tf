locals {
  worksheet_key  = lower(replace(replace(trimspace(var.worksheet_name), ".", ""), " ", "-"))
  import_name    = "${var.department.identifier}-${local.worksheet_key}"
}
