module "uk_org_hackney" {
  source = "./zones/uk-org-hackney"
  tags   = module.tags.values
}

module "uk_example" {
  source = "./zones/uk-example"
  tags   = module.tags.values
}
