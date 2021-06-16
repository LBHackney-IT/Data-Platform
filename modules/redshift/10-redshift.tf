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

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier        = "${var.identifier_prefix}-redshift-cluster"
  database_name             = "data_platform"
  master_username           = "data_engineers"
  master_password           = "Mustbe8characters"
  node_type                 = "dc2.large"
  cluster_type              = "single-node"
  iam_roles                 = [aws_iam_role.redshift_role.arn]
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift.name
  publicly_accessible       = false
  final_snapshot_identifier = "${var.identifier_prefix}-redshift-cluster-final"
  vpc_security_group_ids    = [aws_security_group.redshift_cluster_security_group.id]
  tags                      = var.tags

}

resource "aws_redshift_subnet_group" "redshift" {
  name       = "${var.identifier_prefix}-redshift"
  subnet_ids = var.subnet_ids_list

  tags = var.tags

}

resource "aws_security_group" "redshift_cluster_security_group" {
  name        = "${var.identifier_prefix}-redshift"
  description = "Specifies the rules for inbound traffic to the Redshift cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allows inbound traffic from BI tools using PostgreSQL protocol"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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