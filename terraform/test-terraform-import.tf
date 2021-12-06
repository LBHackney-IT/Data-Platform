resource "aws_instance" "test_terraform_import" {
  tags                 = module.tags.values
  ami                  = "ami-0cf02899353b55a10"
  instance_type        = "m5.2xlarge"
  subnet_id            = "subnet-025858e5f2c7efb9b"
  iam_instance_profile = "dataplatform-stg-qlik-sense-enterprise"
}