resource "aws_security_group" "redshift_serverless" {
  tags = var.tags

  name                   = "${var.identifier_prefix}-redshift-serverless-${var.namespace_name}-namespace"
  description            = "Restrict access to redshift serverless"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true
}

#TODO: lock these down
resource "aws_security_group_rule" "redshift_serverless_ingress" {
  description       = "Allow all inbound traffic"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redshift_serverless.id
}

resource "aws_security_group_rule" "redshift_serverless_egress" {
  description       = "Allows all outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.redshift_serverless.id
}

