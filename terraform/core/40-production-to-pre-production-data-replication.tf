resource "aws_s3_bucket_replication_configuration" "raw_zone" {
  count  = local.is_production_environment
  role   = var.sync_production_to_pre_production_task_role
  bucket = "s3://dataplatform-prod-raw-zone"

  rule {
    id     = "Production to pre-production raw zone replication"
    status = "Enabled"

    destination {
      bucket  = "s3://dataplatform-stg-raw-zone"
      account = "120038763019"
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:120038763019:key/03a1da8d-955d-422d-ac0f-fd27946260c0"
      }
    }
  }
}
resource "aws_s3_bucket_replication_configuration" "refined_zone" {
  count  = local.is_production_environment
  role   = var.sync_production_to_pre_production_task_role
  bucket = "s3://dataplatform-prod-refined-zone"

  rule {
    id     = "Production to pre-production refined zone replication"
    status = "Enabled"

    destination {
      bucket  = "s3://dataplatform-stg-refined-zone"
      account = "120038763019"
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:120038763019:key/670ec494-c7a3-48d8-ae21-2ef85f2c6d21"
      }
    }
  }
}
resource "aws_s3_bucket_replication_configuration" "trusted_zone" {
  count  = local.is_production_environment
  role   = var.sync_production_to_pre_production_task_role
  bucket = "s3://dataplatform-prod-trusted-zone"

  rule {
    id     = "Production to pre-production trusted zone replication"
    status = "Enabled"

    destination {
      bucket  = "s3://dataplatform-stg-trusted-zone"
      account = "120038763019"
      access_control_translation {
        owner = "Destination"
      }
      encryption_configuration {
        replica_kms_key_id = "arn:aws:kms:eu-west-2:120038763019:key/49166434-f10b-483c-81e4-91f099e4a8a0"
      }
    }
  }
}