locals {
  tags_with_department = merge(var.tags, { "PlatformDepartment" = var.department.identifier })
  is_csv               = split(".", lower(var.worksheets[0].worksheet_name))[1] == "csv" ? true : false
}