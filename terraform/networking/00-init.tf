# Core Infrastructure
provider "aws" {
  region = var.aws_deploy_region
  
  dynamic assume_role {
    for_each = local.environment != "dev" ? [1] : []

      content {
        role_arn     = "arn:aws:iam::${var.aws_deploy_account_id}:role/${var.aws_deploy_iam_role_name}"
        session_name = "Terraform"
      }
  }
}

provider "aws" {
  alias  = "aws_api_account"
  region = var.aws_deploy_region
  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_api_account_id}:role/${var.aws_deploy_iam_role_name}"
    session_name = "Terraform"
  }
}

# General
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  backend "s3" {
    region  = "eu-west-2"
    key     = "tfstate"
    bucket  = "dataplatform-terraform-state"
    encrypt = true
  }
}
