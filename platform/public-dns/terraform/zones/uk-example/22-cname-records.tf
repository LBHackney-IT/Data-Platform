resource "aws_route53_record" "www_example_uk_cname" {
  zone_id = aws_route53_zone.example_uk.zone_id
  name    = "www.example.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["example.uk"]
}
