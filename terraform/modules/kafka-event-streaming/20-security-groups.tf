resource "aws_security_group" "kafka" {
  name        = "${var.short_identifier_prefix}kafka"
  tags        = var.tags
  vpc_id      = var.vpc_id
  description = "Specifies rules for traffic to the kafka cluster"

  ingress {
    description      = "Allows all inbound traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allows all inbound traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allows inbound traffic on Kafka port"
    from_port        = 9094
    to_port          = 9094
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allows inbound traffic on ZooKeeper port"
    from_port        = 2182
    to_port          = 2182
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "allow_outbound_traffic_within_sg" {
  description              = "Allow all outbound traffic within the security group"
  security_group_id        = aws_security_group.kafka.id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
  type                     = "egress"
  source_security_group_id = aws_security_group.kafka.id
}

resource "aws_security_group_rule" "allow_outbound_traffic_to_s3" {
  description       = "Allow outbound traffic to port 443 to allow writing to S3"
  security_group_id = aws_security_group.kafka.id
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "allow_outbound_traffic_to_schema_registry" {
  description              = "Allow outbound traffic to schema registry load balancer "
  security_group_id        = aws_security_group.kafka.id
  protocol                 = "TCP"
  from_port                = 8081
  to_port                  = 8081
  type                     = "egress"
  source_security_group_id = module.schema_registry.load_balancer_security_group_id
}