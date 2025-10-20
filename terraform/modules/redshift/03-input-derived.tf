data "aws_instance" "qlik-ec2-data-gateway-prod" {
  filter {
    name   = "tag:Name"
    values = ["qlik-data-gateway-prod"]
  }
}