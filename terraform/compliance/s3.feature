Feature: S3
  
  Scenario: Data must be encrypted at rest
    Given I have aws_s3_bucket defined
    Then it must match one of the following given statements:
        | it must have server_side_encryption_configuration           |
        | it must have aws_s3_bucket_server_side_encryption_configuration |