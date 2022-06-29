Feature: DynamoDB

  Scenario: Ensure BackupPolicy tag is present
    Given I have aws_dynamodb_table defined
    Then it must contain tags
    And it must contain BackupPolicy

  Scenario: Ensure point in time recovery enabled
    Given I have aws_dynamodb_table defined
    Then it must contain point_in_time_recovery
    And its enabled property must be true
