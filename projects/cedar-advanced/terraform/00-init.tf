# AppStream Infrastructure
provider "aws" {
  alias   = "appstream"
  profile = var.cedaradvanced_profile
  region  = var.appstream_region
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
