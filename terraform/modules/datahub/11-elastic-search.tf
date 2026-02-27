resource "aws_elasticsearch_domain" "es" {
  domain_name           = "${var.short_identifier_prefix}elasticsearch"
  elasticsearch_version = "7.9"

  cluster_config {
    instance_type          = "m4.large.elasticsearch"
    zone_awareness_enabled = true
    instance_count         = 3

    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  vpc_options {
    subnet_ids         = var.vpc_subnet_ids
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

  tags = var.tags
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