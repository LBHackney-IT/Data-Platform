# This grabs the latest version of Windows AMI
resource "tls_private_key" "qlik_sense_server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "qlik_sense_server_key" {
  tags = var.tags

  name        = "/${var.identifier_prefix}/ec2/qlik_sense_server_key"
  type        = "SecureString"
  description = "The private key for the EC2 Qlik Sense instance"
  value       = tls_private_key.qlik_sense_server_key.private_key_pem
}

resource "aws_key_pair" "qlik_sense_server_key" {
  tags = var.tags

  key_name   = "${var.identifier_prefix}-qlik-sense"
  public_key = tls_private_key.qlik_sense_server_key.public_key_openssh
}

data "aws_iam_policy_document" "qlik_sense_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "qlik_sense" {
  tags = var.tags

  name               = "${var.identifier_prefix}-qlik-sense"
  assume_role_policy = data.aws_iam_policy_document.qlik_sense_assume_role.json
}

// Find the AmazonSSMManagedInstanceCore Managed policy so that we can use the ARN
data "aws_iam_policy" "amazon_ssm_managed_instance_core" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "qlik_sense_ssm_policy" {
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
  role       = aws_iam_role.qlik_sense.id
}

resource "aws_iam_instance_profile" "qlik_sense" {
  tags = var.tags

  name = "${var.identifier_prefix}-qlik-sense"
  role = aws_iam_role.qlik_sense.id
}

resource "aws_security_group" "qlik_sense" {
  name                   = "${var.short_identifier_prefix}qlik-sense"
  description            = "Restricts access to Qlik Sense EC2 instances"
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
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow inbound HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow inbound RDP traffic"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  tags = merge(var.tags, {
    "Name" : "Qlik Sense Server"
  })
}

#manually added/managed value
data "aws_secretsmanager_secret" "central_backup_role_arn" {
  count = var.is_production_environment ? 1 : 0
  name  = "${var.identifier_prefix}-manually-managed-value-central-backup-role-arn"
}

data "aws_secretsmanager_secret_version" "central_backup_role_arn" {
  count     = var.is_production_environment ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.central_backup_role_arn[0].id
}

data "aws_iam_policy_document" "key_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = var.is_production_environment ? [1] : []

    content {
      sid    = "AllowCentralBackupVaultAccessToThisKey"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [data.aws_secretsmanager_secret_version.central_backup_role_arn[0].secret_string]
      }

      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt",
        "kms:RetireGrant",
        "kms:CreateGrant"
      ]

      resources = [
        "*"
      ]
    }
  }
}

resource "aws_kms_key" "key" {
  tags = var.tags

  description             = "Qlik Sense EBS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.key_policy.json
}

resource "aws_kms_alias" "key_alias" {
  name          = lower("alias/${var.identifier_prefix}-ebs-qlik-sense")
  target_key_id = aws_kms_key.key.key_id
}
