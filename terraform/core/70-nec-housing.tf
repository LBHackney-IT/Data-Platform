module "file_sync_destination_nec" {
  source      = "git::https://github.com/LBHackney-IT/ce-file-sync-modules.git//destination?ref=64aa50415de498e360d2aa89694870ca810ea457" # v0.5.0
  tags        = merge(module.tags.values, { "Environment" = lower(var.environment) })
  application = "nec-housing"
  environment = var.environment
  sftp_host   = "172.26.130.37"
  sftp_port   = "22"
  lambda_vpc_config = {
    subnet_ids         = local.subnet_ids_list
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_security_group" "lambda_sg" {
  name   = "nec-sync-destination"
  vpc_id = data.aws_vpc.network.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = module.tags.values
}
