# See https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md
config {

}

plugin "aws" {
  enabled = true
  version = "0.10.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  deep_check = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags = ["AutomationBuildUrl", "Environment", "Team", "Department", "Application", "Phase", "Stack", "Project", "Confidentiality"]
  exclude = ["aws_s3_bucket_object"] 
}

rule "terraform_module_pinned_source" {
  enabled = false
}
