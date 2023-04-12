resource "aws_security_group" "snapshot_db" {
  name                   = var.instance_name
  description            = "Restrict access to snapshot database"
  vpc_id                 = var.vpc_id
  tags                   = var.tags
}

resource "aws_security_group_rule" "allow_all_outbound_traffic" {
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.snapshot_db.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "allow_mysql_inbound_traffic_within_the_security_group" {
  description       = "Allow indbound traffic to MySQL within security group"
  security_group_id = aws_security_group.snapshot_db.id
  protocol          = "TCP"
  from_port         = 3306
  to_port           = 3306
  type              = "ingress"
  self              = true
}
