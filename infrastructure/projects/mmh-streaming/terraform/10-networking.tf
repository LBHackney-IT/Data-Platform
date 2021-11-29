resource "aws_vpc" "vpc" {
  cidr_block = var.core_cidr
}

resource "aws_subnet" "subnet_az1" {
  availability_zone = var.core_azs[0]
  cidr_block        = var.core_cidr_blocks[0]
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az2" {
  availability_zone = var.core_azs[1]
  cidr_block        = var.core_cidr_blocks[1]
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az3" {
  availability_zone = var.core_azs[2]
  cidr_block        = var.core_cidr_blocks[2]
  vpc_id            = aws_vpc.vpc.id
}