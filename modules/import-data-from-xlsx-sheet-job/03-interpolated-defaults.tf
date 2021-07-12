locals {
  import_name = "${var.department_folder_name}-${lower(replace(var.worksheet_name, " ", "-"))}"
}
