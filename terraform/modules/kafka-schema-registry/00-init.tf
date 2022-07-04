/* This defines the configuration of Terraform and AWS required Terraform Providers.
   As this is a module, we don't have any explicity Provider blocks declared, as these
   will be inherited from the parent Terraform.
*/
terraform {
  required_version = ">= 0.14.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
  }
}
