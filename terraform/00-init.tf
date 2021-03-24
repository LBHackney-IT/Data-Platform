# Core Infrastructure
provider "aws" {
  alias   = "core"
  profile = var.dataplatform_profile
  region  = var.core_region
}

# General
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    region  = "eu-west-2"
    key     = "tf-remote-state"
    bucket  = "hackeny-data-platform-terraform-state"
    encrypt = true
  }
}
