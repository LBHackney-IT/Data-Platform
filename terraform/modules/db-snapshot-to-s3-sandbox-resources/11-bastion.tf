data "aws_ami" "latest_amazon_linux_2" {
  provider    = aws.aws_sandbox_account
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Use Amazon Linux 2 AMI (HVM) SSD Volume Type
  name_regex = "^amzn2-ami-hvm-.*x86_64-gp2"
  # Owner: Amazon
  owners = ["137112412989"]
}

data "aws_iam_policy_document" "ec2_assume_role" {
  provider = aws.aws_sandbox_account
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "bastion" {
  provider = aws.aws_sandbox_account
  tags     = var.tags

  name               = "${var.identifier_prefix}-sandbox-bastion"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy" "amazon_ssm_managed_instance_core" {
  provider = aws.aws_sandbox_account
  name     = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion" {
  provider   = aws.aws_sandbox_account
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
  role       = aws_iam_role.bastion.id
}

resource "aws_iam_instance_profile" "bastion" {
  provider = aws.aws_sandbox_account
  tags     = var.tags

  name = "${var.identifier_prefix}-sandbox-bastion-profile"
  role = aws_iam_role.bastion.id
}

resource "aws_security_group" "bastion" {
  provider               = aws.aws_sandbox_account
  name                   = "${var.identifier_prefix}-sandbox-bastion"
  description            = "Restrict traffic to bastion host"
  vpc_id                 = var.aws_sandbox_vpc_id
  tags                   = var.tags
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "bastion_egress" {
  provider                 = aws.aws_sandbox_account
  description              = "Allow outbound to postgres"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "TCP"
  security_group_id        = aws_security_group.bastion.id
  source_security_group_id = aws_security_group.rds_snapshot_to_s3.id
}

resource "aws_security_group_rule" "bastion_egress_to_systems_manager" {
  provider          = aws.aws_sandbox_account
  description       = "Allow outbound to Systems Manager"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
}

resource "aws_instance" "bastion" {
  provider = aws.aws_sandbox_account
  tags = merge(var.tags, {
    "Name" : "${var.identifier_prefix}-sandbox-bastion",
    "OOOShutdown" : "true"
  })

  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = "t3.micro"

  key_name             = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.bastion.name

  subnet_id                   = var.aws_sandbox_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = false

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}

resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "bastion_key" {
  provider = aws.aws_sandbox_account
  tags     = var.tags

  name        = "/${var.identifier_prefix}/ec2/sandbox_bastion_key"
  type        = "SecureString"
  description = "The private key for the EC2 sandbox bastion instance"
  value       = tls_private_key.bastion_key.private_key_pem
}

resource "aws_key_pair" "generated_key" {
  provider = aws.aws_sandbox_account
  tags     = var.tags

  key_name   = "${var.identifier_prefix}-sandbox-bastion"
  public_key = tls_private_key.bastion_key.public_key_openssh
}
