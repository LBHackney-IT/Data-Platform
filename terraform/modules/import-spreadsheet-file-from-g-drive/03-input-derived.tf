locals {
  tags_with_department = merge(var.tags, { "PlatformDepartment" = var.department.identifier })
  file_name_list       = split(".", lower(var.worksheets[0].worksheet_name))
  is_csv               = local.file_name_list[length(local.file_name_list) - 1] == "csv" ? true : false
}