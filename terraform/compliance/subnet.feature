Feature: Subnets

  Scenario: Ensure a multi-layered network architecture
    Given I have aws_subnet defined
    When I count them
    Then I expect the result is more than 2