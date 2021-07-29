data "aws_ssoadmin_instances" "sso_instances" {
  provider = aws.aws_hackit_account
}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.sso_instances.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)[0]
}

output "arn" {
  value = local.sso_instance_arn
}

output "identity_store_id" {
  value = local.identity_store_id
}

data "aws_identitystore_group" "example" {
  provider = aws.aws_hackit_account
  identity_store_id = local.identity_store_id

  filter {
    attribute_path  = "DisplayName"
    attribute_value = "saml-aws-data-platform-power-user@hackney.gov.uk"
  }
}

output "group_id" {
  value = data.aws_identitystore_group.example.id
}

output "group_display_name" {
  value = data.aws_identitystore_group.example.display_name
}