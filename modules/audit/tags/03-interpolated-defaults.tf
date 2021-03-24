/* This defines local values that are re-usable expressions that are used in this module.

   See https://www.terraform.io/docs/configuration/locals.html
*/
locals {
  tags = map(
    "AutomationBuildUrl", var.automation_build_url,
    "Environment", var.environment,
    "Team", var.team,
    "Department", var.department,
    "Application", var.application,
    "Phase", var.phase,
    "Stack", var.stack,
    "Project", var.project,
  "Confidentiality", var.confidentiality)

  tags_merged = merge(local.tags, var.custom_tags)
}
  
