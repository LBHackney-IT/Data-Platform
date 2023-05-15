variable "tags" {
  description = "AWS tags"
  type        = map(string)
}

variable "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  type        = string
}

variable "aws_sandbox_subnet_ids" {
  description = "AWS sandbox accounts subnet ids"
  type        = list(string)
}

variable "aws_sandbox_account_id" {
  description = "Sandbox account ID"
  type        = string
}

variable "aws_sandbox_vpc_id" {
  description = "VPC id of the sandbox account"
  type        = string
}
