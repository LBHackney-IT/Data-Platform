locals {
  tags_with_department = merge(var.tags, { "PlatformDepartment" = var.department.identifier })
  file_name_list       = split(".", lower(var.worksheets[0].worksheet_name))
  is_csv               = file_name_list[length(file_name_list) - 1] == "csv" ? true : false
}