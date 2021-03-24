resource "aws_route53_record" "sipinternalstls_tcp_hackney_gov_uk_srv" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_sipinternalstls._tcp.hackney.gov.uk"
  type    = "SRV"
  ttl     = "3600"
  records = ["0 0 5061 sfbpoolfe01.hackney.gov.uk"]
}

resource "aws_route53_record" "autodiscover_tcp_hackney_gov_uk_srv" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "_autodiscover._tcp.hackney.gov.uk"
  type    = "SRV"
  ttl     = "3600"
  records = ["0 0 443 autodiscover.hackney.gov.uk"]
}
