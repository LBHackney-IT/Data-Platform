locals {
  import_name = "${var.department_folder_name}-repairs-${lower(replace(var.worksheet_name, " ", "-"))}"
}
