# Core Infrastructure
resource "aws_iam_instance_profile" "sequel_proval_instance_profile" {
  provider = aws.core
  name = "sequel_proval_instance_profile"
  role = aws_iam_role.sequel_proval_iam_role.name
}
resource "aws_iam_role" "sequel_proval_iam_role" {
  provider = aws.core
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  name               = "sequel_proval_iam_role"
  # tags = module.tags.values
}
resource "aws_iam_role_policy_attachment" "sequel_proval_iam_role_attach" {
  provider = aws.core
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.sequel_proval_iam_role.name
}
