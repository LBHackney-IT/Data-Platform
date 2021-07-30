resource "aws_ssoadmin_permission_set" "department" {
  name             = "DataPlatformCollaborator${local.department_pascalcase}-DoNotUse"
  description      = "This is a test permission set created by Terraform"
  instance_arn     = var.sso_instance_arn
  session_duration = "PT12H"
  tags             = var.tags
}

resource "aws_ssoadmin_permission_set_inline_policy" "department" {
  inline_policy      = data.aws_iam_policy_document.sso_user_policy.json
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department.arn
}

data "aws_identitystore_group" "department" {
  identity_store_id = var.identity_store_id

  filter {
    attribute_path  = "DisplayName"
    attribute_value = "saml-aws-data-platform-collaborator-parking@hackney.gov.uk"
  }
}

// Added this as I want to see if it fails when it can't be found
data "aws_identitystore_group" "will_fail" {
  identity_store_id = var.identity_store_id

  filter {
    attribute_path  = "DisplayName"
    attribute_value = "purposefully-does-not-exist@hackney.gov.uk"
  }
}