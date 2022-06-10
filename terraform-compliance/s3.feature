Feature: S3
  Scenario: Ensure server side encryption
    Given i have aws_s3_bucket defined
    Then it must contain apply_server_side_encryption_by_default