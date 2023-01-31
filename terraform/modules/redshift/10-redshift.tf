data "aws_iam_policy_document" "redshift_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["redshift.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "redshift_role" {
  tags = var.tags

  name               = "${var.identifier_prefix}-redshift-role"
  assume_role_policy = data.aws_iam_policy_document.redshift_role.json
}
data "aws_iam_policy_document" "redshift" {
  statement {

    actions = [
      "glue:*"
    ]

    resources = [
      "*",
    ]
  }
  statement {
    actions = ["s3:*"]
    resources = [
      "${var.landing_zone_bucket_arn}/*",
      var.landing_zone_bucket_arn,
      "${var.refined_zone_bucket_arn}/*",
      var.refined_zone_bucket_arn,
      "${var.trusted_zone_bucket_arn}/*",
      var.trusted_zone_bucket_arn,
      "${var.raw_zone_bucket_arn}/*",
      var.raw_zone_bucket_arn
    ]
  }
  statement {
    actions = [
      "kms:DescribeCustomKeyStores",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = [
      var.landing_zone_kms_key_arn,
      var.raw_zone_kms_key_arn,
      var.refined_zone_kms_key_arn,
      var.trusted_zone_kms_key_arn,
    ]
  }
}
resource "aws_iam_policy" "redshift_access_policy" {
  name   = "${var.identifier_prefix}-redshift-access-policy"
  policy = data.aws_iam_policy_document.redshift.json
}

resource "aws_iam_role_policy_attachment" "attach_redshift_role" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = aws_iam_policy.redshift_access_policy.arn
}

resource "random_password" "redshift_cluster_master_password" {
  length  = 40
  special = false
}

resource "aws_redshift_parameter_group" "require_ssl" {
  name   = "${var.identifier_prefix}-redshift-parameter-group"
  family = "redshift-1.0"

  parameter {
    name  = "require_ssl"
    value = "true"
  }

  tags = var.tags
}

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier           = "${var.identifier_prefix}-redshift-cluster"
  database_name                = "data_platform"
  master_username              = "data_engineers"
  master_password              = random_password.redshift_cluster_master_password.result
  node_type                    = "dc2.large"
  cluster_type                 = "multi-node"
  number_of_nodes              = 3
  cluster_parameter_group_name = aws_redshift_parameter_group.require_ssl.name
  iam_roles                    = [aws_iam_role.redshift_role.arn]
  cluster_subnet_group_name    = aws_redshift_subnet_group.redshift.name
  publicly_accessible          = false
  final_snapshot_identifier    = "${var.identifier_prefix}-redshift-cluster-final"
  vpc_security_group_ids       = [aws_security_group.redshift_cluster_security_group.id]
  tags                         = var.tags
}

resource "aws_secretsmanager_secret" "redshift_cluster_master_password" {
  tags = var.tags

  name_prefix = "${var.identifier_prefix}-redshift-cluster-master-password"
  description = "Password for the redshift cluster master user "
  kms_key_id  = var.secrets_manager_key
}

resource "aws_secretsmanager_secret_version" "redshift_cluster_master_password" {
  secret_id     = aws_secretsmanager_secret.redshift_cluster_master_password.id
  secret_string = random_password.redshift_cluster_master_password.result
}

resource "aws_redshift_subnet_group" "redshift" {
  name       = "${var.identifier_prefix}-redshift"
  subnet_ids = var.subnet_ids_list

  tags = var.tags

}

data "aws_secretsmanager_secret" "redshift_ingress_rules" {
    name = "${var.identifier_prefix}-manually-managed-value-redshift-ingress-rules"
}

data "aws_secretsmanager_secret_version" "redshift_ingress_rules"{
    secret_id = data.aws_secretsmanager_secret.redshift_ingress_rules.id
}

locals {
  redshift_ingress_rules = jsondecode(data.aws_secretsmanager_secret_version.redshift_ingress_rules.secret_string)
}

resource "aws_security_group" "redshift_cluster_security_group" {
  name        = "${var.identifier_prefix}-redshift"
  description = "Specifies the rules for inbound traffic to the Redshift cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allows inbound traffic when running queries from the console"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Allows cidr based inbound traffic"
    from_port = 5439
    to_port = 5439
    protocol = "tcp"
    cidr_blocks = local.redshift_ingress_rules["cidr_blocks"]
  }

  ingress {
    description = "Allows security group based inbound traffic"
    from_port = 5439
    to_port = 5439
    protocol = "tcp"
    security_groups = local.redshift_ingress_rules["security_groups"]
  }

  egress {
    description      = "Allows all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}