resource "aws_route53_record" "example_uk_mx" {
  zone_id = aws_route53_zone.example_uk.zone_id
  name    = "example.uk"
  type    = "MX"
  ttl     = "3600"
  records = ["10 mx.1.example.uk", "10 mx.2.example.uk"]
}
