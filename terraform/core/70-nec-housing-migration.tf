module "file_sync_destination_nec" {
  source = "git::https://github.com/LBHackney-IT/ce-file-sync-modules.git//destination?ref=4e033085b7927fb996e27e170f0d67841e696e90"

  tags        = module.tags.values
  application = "nec_housing"
  environment = var.environment
  sftp_host   = "172.26.130.37"
  sftp_port   = 22
  lambda_vpc_config = {
    subnet_ids         = local.subnet_ids_list
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_security_group" "lambda_sg" {
  name   = "NEC sftp lambda"
  vpc_id = data.aws_vpc.network.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = module.tags.values
}
