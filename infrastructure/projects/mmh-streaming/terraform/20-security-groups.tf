resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
}