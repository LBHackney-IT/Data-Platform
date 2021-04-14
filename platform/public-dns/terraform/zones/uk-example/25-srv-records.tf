resource "aws_route53_record" "autodiscover_tcp_example_uk_srv" {
  zone_id = aws_route53_zone.example_uk.zone_id
  name    = "_autodiscover._tcp.example.uk"
  type    = "SRV"
  ttl     = "3600"
  records = ["0 0 443 autodiscover.example.uk"]
}
