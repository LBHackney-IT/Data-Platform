resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = "${var.short_identifier_prefix}elasticsearch"
  elasticsearch_version = "OS_1.2"

  cluster_config {
    instance_type          = "m4.large.elasticsearch"
    zone_awareness_enabled = true
    dedicated_master_count = 2
  }

  vpc_options {
    subnet_ids         = data.aws_subnet_ids.subnet_ids.ids
    security_group_ids = [aws_security_group.es.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.short_identifier_prefix}elasticsearch/*"
        }
    ]
}
CONFIG

  tags       = var.tags
  depends_on = [aws_iam_service_linked_role.es]
}

resource "aws_security_group" "es" {
  name   = "${var.short_identifier_prefix}elasticsearch"
  vpc_id = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block,
    ]
  }
}