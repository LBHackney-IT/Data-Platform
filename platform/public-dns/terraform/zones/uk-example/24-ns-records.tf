resource "aws_route53_record" "example_uk_ns" {
  zone_id = aws_route53_zone.example_uk.zone_id
  name    = "subdomain.example.uk"
  type    = "NS"
  ttl     = "3600"
  records = ["ns0.example.uk.", "ns1.example.uk.", "ns2.example.uk."]
}
