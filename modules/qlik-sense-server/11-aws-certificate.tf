resource "aws_acm_certificate" "qlik_sense_server" {
  count = var.is_live_environment ? 1 : 0

  domain_name       = "qliksense.hackney.gov.uk"
  validation_method = "DNS"

  tags = var.tags
}