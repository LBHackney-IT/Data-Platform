locals {
  departments = {
    "social-care" = {
      account_to_share_data_with = "365719730767",
      iam_role_name              = "eu-west-1/AWSReservedSSO_AWSAdministratorAccess_1f8b3e702dfcf5a9",
      s3_read_write_directory    = "social-care",
      s3_read_directories        = []
    },
    "housing" = {
      account_to_share_data_with = "261219435789",
      iam_role_name              = "eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
      s3_read_write_directory    = "housing",
      s3_read_directories        = []
    }
  }
}
