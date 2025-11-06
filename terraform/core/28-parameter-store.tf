resource "aws_ssm_parameter" "uh_mirror_address" {
  name  = "/${local.identifier_prefix}/${module.department_housing.identifier}/uh_mirror_prod/address"
  type  = "String"
  value = "UPDATE_IN_CONSOLE"
  tags  = module.tags.values

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "uh_mirror_username" {
  name  = "/${local.identifier_prefix}/${module.department_housing.identifier}/uh_mirror_prod/username"
  type  = "String"
  value = "UPDATE_IN_CONSOLE"
  tags  = module.tags.values

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "uh_mirror_password" {
  name  = "/${local.identifier_prefix}/${module.department_housing.identifier}/uh_mirror_prod/password"
  type  = "SecureString"
  value = "UPDATE_IN_CONSOLE"
  tags  = module.tags.values

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "repairs_hub_address" {
  name  = "/${local.identifier_prefix}/${module.department_housing.identifier}/repairs_hub_prod/address"
  type  = "String"
  value = "UPDATE_IN_CONSOLE"
  tags  = module.tags.values

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "repairs_hub_username" {
  name  = "/${local.identifier_prefix}/${module.department_housing.identifier}/repairs_hub_prod/username"
  type  = "String"
  value = "UPDATE_IN_CONSOLE"
  tags  = module.tags.values

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "repairs_hub_password" {
  name  = "/${local.identifier_prefix}/${module.department_housing.identifier}/repairs_hub_prod/password"
  type  = "SecureString"
  value = "UPDATE_IN_CONSOLE"
  tags  = module.tags.values

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

