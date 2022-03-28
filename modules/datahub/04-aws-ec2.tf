resource "aws_instance" "datahub" {
  tags = merge(var.tags, {
    "Name" : "${var.identifier_prefix}-datahub",
    "OOOShutdown" : "true"
  })

  ami                  = var.aws_ami_id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.datahub.name

  subnet_id              = var.vpc_subnet_ids
  vpc_security_group_ids = [aws_security_group.datahub.id]
  user_data_base64       = data.template_cloudinit_config.config.rendered

  lifecycle {
    ignore_changes = [ami, subnet_id]
  }
}

data "template_file" "init_script" {
  template = file("${path.module}/installation/init.tpl")
}

data "template_file" "docker_compose_file" {
  template = file("${path.module}/installation/docker-compose.yml")
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.init_script.rendered
  }

  part {
    filename     = "docker-compose.yml"
    content_type = "text/x-shellscript"
    content      = data.template_file.docker_compose_file.rendered
  }
}


resource "tls_private_key" "datahub_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "datahub_key" {
  tags = var.tags

  name        = "/${var.identifier_prefix}/ec2/datahub_key"
  type        = "SecureString"
  description = "The private key for the EC2 datahub instance"
  value       = tls_private_key.datahub_key.private_key_pem
}

resource "aws_key_pair" "generated_key" {
  tags = var.tags

  key_name   = "${var.identifier_prefix}-datahub"
  public_key = tls_private_key.datahub_key.public_key_openssh
}