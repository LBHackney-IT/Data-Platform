# Core Infrastructure
provider "aws" {
  region = "eu-west-2"
}

# General
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}
