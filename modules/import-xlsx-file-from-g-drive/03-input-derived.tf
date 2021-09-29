locals {
  tags_with_department = merge(var.tags, { "PlatformDepartment" = var.department_folder_name })
}