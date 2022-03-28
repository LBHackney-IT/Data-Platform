data "aws_vpc" "network" {
  id = data.aws_ssm_parameter.aws_vpc_id.value
}

data "aws_subnet_ids" "network" {
  vpc_id = data.aws_ssm_parameter.aws_vpc_id.value
}

data "aws_subnet" "network" {
  for_each = data.aws_subnet_ids.network.ids
  id       = each.value
}

resource "random_id" "index" {
  byte_length = 2
}

# This show a method of randomly selecting a subnet from the VPC to deploy into.
locals {
  subnet_ids_list         = tolist(data.aws_subnet_ids.network.ids)
  subnet_ids_random_index = random_id.index.dec % length(data.aws_subnet_ids.network.ids)
  instance_subnet_id      = local.subnet_ids_list[local.subnet_ids_random_index]
}

# This grabs the latest version of Amazon Linux 2
data "aws_ami" "latest_amazon_linux_2" {
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

resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "bastion_key" {
  tags = module.tags.values

  name        = "/${local.identifier_prefix}/ec2/bastion_key"
  type        = "SecureString"
  description = "The private key for the EC2 bastion instance"
  value       = tls_private_key.bastion_key.private_key_pem
}

resource "aws_key_pair" "generated_key" {
  tags = module.tags.values

  key_name   = "${local.identifier_prefix}-bastion"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "bastion" {
  tags = module.tags.values

  name               = "${local.identifier_prefix}-bastion"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

data "aws_iam_policy" "amazon_ssm_managed_instance_core" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion" {
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
  role       = aws_iam_role.bastion.id
}

resource "aws_iam_instance_profile" "bastion" {
  tags = module.tags.values

  name = "${local.identifier_prefix}-bastion-profile"
  role = aws_iam_role.bastion.id
}

resource "aws_security_group" "bastion" {
  name                   = "${local.identifier_prefix}-bastion"
  description            = "Restricts access to Bastion EC2 instances by only allowing SSH access"
  vpc_id                 = data.aws_vpc.network.id
  revoke_rules_on_delete = true

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(module.tags.values, {
    "Name" : "Bastion"
  })
}

resource "aws_instance" "bastion" {
  tags = merge(module.tags.values, {
    "Name" : "${local.identifier_prefix}-bastion",
    "OOOShutdown" : "true"
  })

  ami                  = data.aws_ami.latest_amazon_linux_2.id
  instance_type        = "t3.micro"
  key_name             = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.bastion.name

  subnet_id              = local.instance_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  lifecycle {
    ignore_changes = [ami, subnet_id]
  }
}
