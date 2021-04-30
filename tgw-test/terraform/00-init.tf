# AppStream Infrastructure
provider "aws" {
  alias   = "core"
  profile = var.core_profile
  region  = var.core_region
}

# General
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
