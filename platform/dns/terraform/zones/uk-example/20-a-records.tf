resource "aws_route53_record" "example_uk_a" {
  zone_id = aws_route53_zone.example_uk.zone_id
  name    = "example.uk."
  type    = "A"
  ttl     = "3600"
  records = ["1.1.1.1"]
}
