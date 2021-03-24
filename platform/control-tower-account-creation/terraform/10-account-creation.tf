module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "0.13.0"

  name = "control-tower-account-creation"

  hash_key = "AccountName"

  attributes = [
    {
      name = "AccountName"
      type = "S"
    }
  ]

  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = module.tags.values
}
