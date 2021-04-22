resource "aws_route53_record" "reportaproblem_hackney_gov_uk_ns" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "reportaproblem.hackney.gov.uk"
  type    = "NS"
  ttl     = "3600"
  records = ["ns2.ukcod.org.uk.", "ns0.ukcod.org.uk.", "ns1.ukcod.org.uk."]
}

# resource "aws_route53_record" "hackney_gov_uk_ns" {
#   zone_id = aws_route53_zone.hackney_gov_uk.zone_id
#   name    = "hackney.gov.uk"
#   type    = "NS"
#   ttl     = "3600"
#   records = ["ns1.virginmedia.net", "ns2.virginmedia.net", "ns3.virginmedia.net", "ns4.virginmedia.net"]
# }

resource "aws_route53_record" "email_hackney_gov_uk_ns" {
  zone_id = aws_route53_zone.hackney_gov_uk.zone_id
  name    = "email.hackney.gov.uk"
  type    = "NS"
  ttl     = "3600"
  records = ["ns0.dns.dotdigital.com", "ns1.dns.dotdigital.com", "ns2.dns.dotdigital.com"]
}
