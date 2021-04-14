# Core Infrastructure
provider "aws" {
  alias   = "core"
  profile = var.profile
  region  = var.core_region
}


# General
terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
