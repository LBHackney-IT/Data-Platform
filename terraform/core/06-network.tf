data "aws_vpc" "network" {
  id = data.aws_ssm_parameter.aws_vpc_id.value
}

data "aws_subnets" "network" {
  filter {
    name   = "vpc-id"
    values = [data.aws_ssm_parameter.aws_vpc_id.value]
  }
}

data "aws_subnet" "network" {
  for_each = toset(data.aws_subnets.network.ids)
  id       = each.value
}

resource "random_id" "index" {
  byte_length = 2
}

# This show a method of randomly selecting a subnet from the VPC to deploy into.
locals {
  subnet_ids_list         = tolist(data.aws_subnets.network.ids)
  subnet_ids_random_index = random_id.index.dec % length(data.aws_subnets.network.ids)
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

  subnet_id                   = local.instance_subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = false

  lifecycle {
    ignore_changes = [ami, subnet_id]
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
}

resource "aws_flow_log" "vpc" {
  tags = module.tags.values

  log_destination      = aws_cloudwatch_log_group.vpc_flow_log.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn


  traffic_type = "ALL"

  vpc_id = data.aws_vpc.network.id
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "${local.identifier_prefix}-vpc-flow-log"
  retention_in_days = 30
  tags              = module.tags.values
}

resource "aws_iam_role" "vpc_flow_logs" {
  name               = "${local.identifier_prefix}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_assume_role.json
  tags               = module.tags.values
}

data "aws_iam_policy_document" "vpc_flow_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name   = "${local.identifier_prefix}-cloudwatch-flow-logs"
  role   = aws_iam_role.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}
