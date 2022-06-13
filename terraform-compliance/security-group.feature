Feature: Security Groups

  @exclude_aws_security_group.service_endpoint.
  Scenario: Ensure no publicly open ports
    Given I have aws_security_group defined
    When it has ingress
    Then it must have ingress
    Then it must not have tcp protocol and port 1024-65535 for 0.0.0.0/0