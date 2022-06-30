Feature: Elastic Search

  Scenario: Ensure it is deployed in a VPC
    Given I have aws_elasticsearch_domain defined
    Then it must contain vpc_options

  Scenario: Ensure OpenSearch clusters are encrypted at rest
    Given I have aws_elasticsearch_domain defined
    Then it must contain encrypt_at_rest
    And its enabled property must be true

  Scenario: Ensure minimum instance count is 2
    Given I have aws_elasticsearch_domain defined
    Then it must contain cluster_config
    And it must contain instance_count
    And its value must be greater and equal to 2

  Scenario: Ensure instance type is small or medium
    Given I have aws_elasticsearch_domain defined
    Then it must contain cluster_config
    And it must contain instance_type
    And its value must match the "^(t3\.small\.elasticsearch|t3\.medium\.elasticsearch)" regex