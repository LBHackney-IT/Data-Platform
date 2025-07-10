# Core Infrastructure
provider "aws" {
  region = var.aws_deploy_region
  
  dynamic assume_role {
    for_each = local.is_live_environment ? [1] : []
    
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

provider "aws" {
  alias  = "aws_hackit_account"
  region = "eu-west-1"
  
  dynamic assume_role {
    for_each = local.is_live_environment ? [1] : [] 
    
    content {
      role_arn     = "arn:aws:iam::${var.aws_hackit_account_id}:role/${var.aws_deploy_iam_role_name}"
      session_name = "DataPlatform"
    }
  }
}

provider "google" {
  region      = "europe-west2"
  zone        = "europe-west2-a"
  credentials = "../../google_service_account_creds.json"
  project     = var.google_project_id
}

# General
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    region  = "eu-west-2"
    key     = "tfstate-etl"
    bucket  = "dataplatform-terraform-state"
    encrypt = true
  }
}
