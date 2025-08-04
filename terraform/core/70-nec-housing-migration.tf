module "file_sync_destination_nec" {
  source = "git::https://github.com/LBHackney-IT/ce-file-sync-modules.git//destination?ref=82daf9901f3cb49b851213813ceab32ce88edb81" # v.0.4.0

  tags        = module.tags.values
  application = "nec_housing"
  environment = var.environment
  sftp_host   = "172.26.130.37"
  sftp_port   = 22
  lambda_vpc_config = {
    # TODO: think this needs to be set up?
  }
}
