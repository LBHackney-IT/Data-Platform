locals {
  worksheet_key = lower(replace(replace(trimspace(var.worksheet_name), ".", ""), " ", "-"))
  catalog_table = lower(replace(replace(replace(trimspace(var.data_set_name), ".", ""), "/[^a-zA-Z0-9]+/", "_"), "/_+/", "_"))
  import_name   = "${var.department.identifier}-${local.worksheet_key}"
}
