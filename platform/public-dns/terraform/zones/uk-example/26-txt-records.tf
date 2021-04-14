resource "aws_route53_record" "txt_example_uk_txt" {
  zone_id = aws_route53_zone.example_uk.zone_id
  name    = "example.uk"
  type    = "TXT"
  ttl     = "3600"
  records = ["some_txt_data"]
}
