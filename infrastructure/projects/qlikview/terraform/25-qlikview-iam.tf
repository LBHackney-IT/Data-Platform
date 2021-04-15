# Core Infrastructure
resource "aws_iam_instance_profile" "qlikview_app_instance_profile" {
  provider = aws.core
  name = "qlikview_app_instance_profile"
  role = aws_iam_role.qlikview_app_iam_role.name
}
resource "aws_iam_role" "qlikview_app_iam_role" {
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
  name               = "qlikview_app_iam_role"
  # tags = module.tags.values
}
resource "aws_iam_role_policy_attachment" "qlikview_app_iam_role_attach" {
  provider = aws.core
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.qlikview_app_iam_role.name
}