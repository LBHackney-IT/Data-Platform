# This grabs the latest version of Windows AMI
data "aws_ami" "latest_windows" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Owner: Amazon
  owners = ["801119661308"]
}

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

resource "aws_ssm_parameter" "qlik_sense_admin_password" {
  tags = var.tags

  name        = "/${var.identifier_prefix}/ec2/qlik_sense_admin_password"
  type        = "SecureString"
  description = "The Administrator password for the Qlik Sense instance"
  value       = rsadecrypt(aws_instance.qlik_sense.password_data, tls_private_key.qlik_sense_server_key.private_key_pem)
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
  name                   = "${var.identifier_prefix}-qlik-sense"
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
    description      = "Allow inbound RDP traffic"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    "Name" : "Qlik Sense"
  })
}

resource "aws_instance" "qlik_sense" {
  tags = merge(var.tags, {
    "Name" : "${var.identifier_prefix}-qlik-sense",
  })

  ami                  = data.aws_ami.latest_windows.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.qlik_sense_server_key.key_name
  iam_instance_profile = aws_iam_instance_profile.qlik_sense.name

  subnet_id              = local.instance_subnet_id
  vpc_security_group_ids = [aws_security_group.qlik_sense.id]
  get_password_data      = "true"

  lifecycle {
    ignore_changes = [subnet_id]
  }
}