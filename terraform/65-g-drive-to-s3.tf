# This is no longer needed, but keeping this in as an example how the module should be used
# module "repairs_spreadsheet" {
#   source                         = "../modules/g-drive-to-s3"
#   tags                           = module.tags.values
#   identifier_prefix              = local.identifier_prefix
#   lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
#   zone_kms_key_arn               = module.landing_zone.kms_key_arn
#   zone_bucket_arn                = module.landing_zone.bucket_arn
#   zone_bucket_id                 = module.landing_zone.bucket_id
#   lambda_name                    = "repairs_spreadsheet"
#   service_area                   = "housing"
#   file_id                        = "1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq"
#   file_name                      = "Electrical-Mechnical-Fire-Safety-Temp-order-number-WC-12.10.20R1.xlsx"
# }
