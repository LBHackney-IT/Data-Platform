locals {
  tags_with_department = merge(var.tags, { "PlatformDepartment" = var.department.identifier })
  file_name_list       = split(".", lower(var.input_file_name))
  is_csv               = length(local.file_name_list) > 0 && local.file_name_list[length(local.file_name_list) - 1] == "csv" ? true : false
}