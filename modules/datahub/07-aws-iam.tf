resource "aws_iam_role" "datahub" {
  tags = var.tags

  name               = "${var.identifier_prefix}-bastion"
  assume_role_policy = data.aws_iam_policy_document.datahub.json
}

resource "aws_iam_role_policy_attachment" "datahub" {
  policy_arn = var.amazon_ssm_managed_instance_core_arn
  role       = aws_iam_role.datahub.id
}

resource "aws_iam_instance_profile" "datahub" {
  tags = var.tags
  name = "${var.identifier_prefix}-datahub-profile"
  role = aws_iam_role.datahub.id
}

data "aws_iam_policy_document" "datahub" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}