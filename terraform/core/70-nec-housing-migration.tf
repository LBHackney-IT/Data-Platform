module "file_sync_destination_nec" {
  # TODO: use previous version
  source = "git::https://github.com/LBHackney-IT/ce-file-sync-modules.git//destination?ref=caa59d0852914b52245295c57695a52940aa4a31" # v.0.3.2

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
}
