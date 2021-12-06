resource "aws_instance" "test_terraform_import" {
  tags                 = module.tags.values
  ami                  = "ami-0d37e07bd4ff37148"
  instance_type        = "t2.micro"
  subnet_id            = "subnet-09de42c945f5507df"
  iam_instance_profile = "el-ec2"
}