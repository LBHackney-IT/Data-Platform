Feature: No security groups allowing public access
  In order to improve security
  As engineers
  We'll ensure that no security groups allow public access to resources

  Scenario: Ensure no publicly open ports
    Given I have aws_security_group defined
    When it has ingress
    Then it must have ingress
    Then it must not have tcp protocol for 0.0.0.0/0