# Core Infrastructure
# Core Infrastructure - Key Generation
resource "aws_key_pair" "generated_key" {
  provider = aws.ss_primary

  key_name   = var.key_name
  public_key = tls_private_key.private_key.public_key_openssh
  tags = merge(
  module.tags.values,
  {
    "Name" = format("NgFw-%s", var.environment)
  }
  )
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Core Infrastructure - Private Key Secret
resource "aws_secretsmanager_secret" "private_key" {
  provider = aws.ss_primary

  name = format("%s_%s_private_key", var.application, var.environment)
}

resource "aws_secretsmanager_secret_version" "private_key" {
  provider = aws.ss_primary

  secret_id     = aws_secretsmanager_secret.private_key.id
  secret_string = tls_private_key.private_key.private_key_pem
}

# Core Infrastructure - Public Key Secret
resource "aws_secretsmanager_secret" "public_key" {
  provider = aws.ss_primary

  name = format("%s_%s_public_key", var.application, var.environment)
}

resource "aws_secretsmanager_secret_version" "public_key" {
  provider = aws.ss_primary

  secret_id     = aws_secretsmanager_secret.public_key.id
  secret_string = tls_private_key.private_key.public_key_openssh
}
