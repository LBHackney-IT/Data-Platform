module "department_housing" {
  source = "../modules/department"
  tags = module.tags.values
}

module "department_parking" {
  source = "../modules/department"
  tags = module.tags.values
}

module "department_finance" {
  source = "../modules/department"
  tags = module.tags.values
}