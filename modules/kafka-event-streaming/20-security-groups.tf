resource "aws_security_group" "kafka" {
  name        = "${var.identifier_prefix}kafka"
  tags        = var.tags
  vpc_id      = var.vpc_id
  description = "Specifies rules for traffic to the kafka cluster"


# TODO: Allow only traffic from port 80 & 443
  ingress {
    description      = "Allows all inbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}