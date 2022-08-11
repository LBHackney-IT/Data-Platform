resource "aws_security_group" "kafka-test" {
  name        = "${var.identifier_prefix}kafka-test"
  tags        = var.tags
  vpc_id      = var.vpc_id
  description = "Specifies rules for traffic to the kafka-test lambda"

  egress {
    description      = "Allow all outbound traffic within the security group"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
