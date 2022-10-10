Feature: S3

  @exclude_aws_s3_bucket.ssl_connection_resources\[0\]
  Scenario: Data must be encrypted at rest
    Given I have aws_s3_bucket defined
    Then it must have server_side_encryption_configuration
