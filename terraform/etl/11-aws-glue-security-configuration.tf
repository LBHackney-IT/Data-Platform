resource "aws_glue_security_configuration" "glue_job_security_configuration_to_raw" {
  name = "${local.identifier_prefix}-config-to-raw"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = module.raw_zone_data_source.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}

resource "aws_glue_security_configuration" "glue_job_security_configuration_to_refined" {
  name = "${local.identifier_prefix}-config-to-refined"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = module.refined_zone_data_source.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}

resource "aws_glue_security_configuration" "glue_job_security_configuration_to_trusted" {
  name = "${local.identifier_prefix}-config-to-trusted"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = module.trusted_zone_data_source.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}
