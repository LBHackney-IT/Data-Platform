# Core Infrastructure
provider "aws" {
  region = var.aws_deploy_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_deploy_account}:role/${var.aws_deploy_iam_role_name}"
    session_name = "Terraform"
  }
}

provider "google" {
  region = "europe-west2"
  zone   = "europe-west2-a"
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
    bucket  = "dataplatform-test-lambda"
    encrypt = true
  }
}
