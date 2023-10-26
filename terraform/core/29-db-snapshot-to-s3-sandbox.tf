#These reources are for development use only to setup RDS snapshot to S3 process cross account between sandbox and DP dev accounts

# 1. Deploy this first to get the database and bastion host in place
module "db_snapshot_to_s3_sandbox_resources" {
  count                  = 0
  source                 = "../modules/db-snapshot-to-s3-sandbox-resources"
  tags                   = module.tags.values
  identifier_prefix      = local.identifier_prefix
  aws_sandbox_subnet_ids = var.aws_sandbox_subnet_ids
  aws_sandbox_account_id = var.aws_sandbox_account_id
  aws_sandbox_vpc_id     = var.aws_sandbox_vpc_id

  providers = {
    aws                     = aws
    aws.aws_sandbox_account = aws.aws_sandbox_account
  }
}

# 2. Copy the deployed sandbox database name to rds_instance_ids variable in the env.tfvars file. This is required for step 3.

# 3. lambda_artefact_storage_for_sandbox_account and db_snapshot_to_s3_sandbox can be deployed at the same time
module "lambda_artefact_storage_for_sandbox_account" {
  count             = 0
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Lambda Artefact Storage"
  bucket_identifier = "sandbox-lambda-artefact-storage"

  providers = {
    aws = aws.aws_sandbox_account
  }
}

#module "db_snapshot_to_s3_sandbox" {
#  count                          = 0
#  source                         = "../modules/db-snapshot-to-s3"
#  tags                           = module.tags.values
#  project                        = var.project
#  environment                    = var.environment
#  identifier_prefix              = local.identifier_prefix
#  lambda_artefact_storage_bucket = module.lambda_artefact_storage_for_sandbox_account[0].bucket_id
#  zone_kms_key_arn               = module.raw_zone.kms_key_arn
#  zone_bucket_arn                = module.raw_zone.bucket_arn
#  zone_bucket_id                 = module.raw_zone.bucket_id
#  rds_export_storage_bucket_arn  = module.rds_export_storage.bucket_arn
#  rds_export_storage_kms_key_arn = module.rds_export_storage.kms_key_arn
#  service_area                   = "unrestricted"
#  rds_instance_ids               = var.rds_instance_ids
#  aws_account_suffix             = "-sandbox"
#
#  providers = {
#    aws = aws.aws_sandbox_account
#  }
#}

#4. Update the raw zone bucket on DP dev account in your workspace with the following bucket and bucket key statements
#   Use these as inputs for bucket_policy_statements and bucket_key_policy_statements in the raw zone bucket module

# sandbox_s3_to_s3_copier_write_access_to_raw_zone_statement = {
#     sid = "AllowSandboxS3toS3CopierWriteAccessToRawZoneUnrestrictedLocation"
#     effect = "Allow"

#     actions = [
#       "s3:ListBucket",
#       "s3:PutObject",
#       "s3:PutObjectAcl"
#     ]
#     principals = {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::${var.aws_sandbox_account_id}:root",
#         "arn:aws:iam::${var.aws_sandbox_account_id}:role/${local.identifier_prefix}-s3-to-s3-copier-lambda"
#       ]
#     }

#     resources = [
#       "${module.raw_zone.bucket_arn}",
#       "${module.raw_zone.bucket_arn}/unrestricted/${replace(lower(local.identifier_prefix), "/[^a-zA-Z0-9]+/", "_")}_sandbox/*" 
#     ]
#   }

#   sandbox_s3_to_s3_copier_raw_zone_key_statement = {
#     sid = "SandboxS3ToS3CopierAccessToRawZoneKey"
#     effect = "Allow"
#     actions = [
#       "kms:Encrypt",
#       "kms:GenerateDataKey*"
#     ]

#     principals = {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::${var.aws_sandbox_account_id}:root"
#         "arn:aws:iam::${var.aws_sandbox_account_id}:role/${local.identifier_prefix}-s3-to-s3-copier-lambda"
#       ]
#     }

#   }

#5. Uncomment the statement in the sandbox database key policy to allow the rds snapshot to s3 lambda role access to the key. This must be done after all other resources have been deployed.

#6. Connect to the database from the bastion host using AWS Session Manager and import some dummy data for testing 
# you can import some test data by following these steps:
#  sudo yum update -y
#  sudo amazon-linux-extras enable postgresql14
#  sudo yum install postgresql-server -y
#  psql --host=<YOUR_DATABASE_HOST> --port=5432 --username=sandbox_db_admin --password --dbname=<YOUR_DATABASE_NAME>
# enter password from secrets manager 
# you can use the following resources for quick setup
# schema: https://github.com/LBHackney-IT/social-care-case-viewer-api/blob/master/database/schema.sql
# seeds: https://github.com/LBHackney-IT/social-care-case-viewer-api/blob/master/database/seeds.sql

#7. Test the setup by taking a manual snapshot of the sandbox database. Once the process is complete you should have data in your DP dev raw zone in the unrestrcited area

#8 To remove the resources and revert the changes follow the steps in reverse order
