# Core Infrastructure
provider "aws" {
  alias   = "core"
  profile = var.aws_deploy_profile
  region  = var.aws_deploy_region
}

provider "google" {
  region  = "europe-west2"
  zone    = "europe-west2-a"
}

# General
terraform {
  required_version = "~> 0.14.3"

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
    bucket  = "dataplatform-internal-stg-tfstate"
    encrypt = true
  }
}
