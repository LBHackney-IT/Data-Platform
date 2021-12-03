resource "aws_instance" "test_terraform_import" {
  ami = "unknown"
  instance_type = "t2.micro"
}