resource "aws_security_group" "datahub_neo4j" {
  name                   = "${var.short_identifier_prefix}datahub-neo4j-alb"
  description            = "Restricts access to the DataHub Neo4j Application Load Balancer"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound HTTP traffic"
    from_port        = local.neo4j.port
    to_port          = local.neo4j.port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound HTTP traffic"
    from_port        = 7687
    to_port          = 7687
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" : "DataHub Neo4j Load Balancer"
  })
}

resource "aws_alb_target_group" "datahub_neo4j" {
  name        = "${var.short_identifier_prefix}datahub-neo4j"
  port        = local.neo4j.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_alb" "datahub_neo4j" {
  name               = "${var.short_identifier_prefix}datahub-neo4j"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.datahub_neo4j.id]
  subnets            = data.aws_subnet.subnets.*.id
}

resource "aws_alb_listener" "datahub_neo4j" {
  load_balancer_arn = aws_alb.datahub_neo4j.arn
  port              = local.neo4j.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.datahub_neo4j.arn
  }
}
