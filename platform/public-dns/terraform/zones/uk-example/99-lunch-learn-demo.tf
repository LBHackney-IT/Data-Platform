resource "aws_route53_record" "lunch_and_learn_example_cname" {
  zone_id = aws_route53_zone.example_uk.zone_id
  name    = "cloud-deployment-awesomeoness.example.uk"
  type    = "CNAME"
  ttl     = "3600"
  records = ["example.uk"]
}
