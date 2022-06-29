resource "tls_private_key" "dev_enpoint_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_ssm_parameter" "dev_enpoint_key" {
  tags = var.tags

  name        = "/${var.identifier_prefix}glue-dev-endpoint-private-key/${var.instance_name}"
  type        = "SecureString"
  description = "The private key for the glue development endpoint"
  value       = tls_private_key.dev_enpoint_key.private_key_pem
}
