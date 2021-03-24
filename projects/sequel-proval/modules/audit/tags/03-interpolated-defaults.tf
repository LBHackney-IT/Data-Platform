/* This defines local values that are re-usable expressions that are used in this module.

   See https://www.terraform.io/docs/configuration/locals.html
*/
locals {
  tags = map(
    "automation_build_url", var.automation_build_url,
    "environment", var.environment,
    "team", var.team,
    "department", var.department,
    "application", var.application,
    "phase", var.phase,
    "stack", var.stack,
    "project", var.project,
  "confidentiality", var.confidentiality)

  tags_merged = merge(local.tags, var.custom_tags)
}
  