resource "aws_route53_zone" "example_uk" {
  name = "example.uk"
  tags = var.tags
}
