# Shared Services Infrastructure
provider "aws" {
  alias  = "ss_primary"
  region = var.ss_primary_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_deploy_account}:role/${var.aws_deploy_iam_role_name}"
    session_name = "Terraform"
  }
}

provider "aws" {
  alias  = "ss_secondary"
  region = var.ss_secondary_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_deploy_account}:role/${var.aws_deploy_iam_role_name}"
    session_name = "Terraform"
  }
}

provider "random" {
}

# General
terraform {
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}
