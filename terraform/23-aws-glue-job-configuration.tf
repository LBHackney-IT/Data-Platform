resource "aws_glue_security_configuration" "glue_job_security_configuration_to_raw" {
  name = "glue-job-security-configuration-to-raw"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = module.raw_zone.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}

resource "aws_glue_security_configuration" "glue_job_security_configuration_to_refined" {
  name = "glue-job-security-configuration-to-refined"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = module.refined_zone.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}

resource "aws_glue_security_configuration" "glue_job_security_configuration_to_trusted" {
  name = "glue-job-security-configuration-to-trusted"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    s3_encryption {
      kms_key_arn        = module.trusted_zone.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}
