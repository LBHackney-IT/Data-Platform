resource "aws_iam_user" "datahub" {
  name = "${var.short_identifier_prefix}datahub-user"
  tags = var.tags
}

resource "aws_iam_access_key" "datahub_access_key" {
  user = aws_iam_user.datahub.name
}

resource "aws_iam_user_policy" "datahub_user_policy" {
  name   = "${var.short_identifier_prefix}datahub-user-policy"
  user   = aws_iam_user.datahub.name
  policy = data.aws_iam_policy_document.datahub_can_assume_role.json
}

resource "aws_iam_role" "datahub_role" {
  tags               = var.tags
  name               = "${var.short_identifier_prefix}datahub-role"
  assume_role_policy = data.aws_iam_policy_document.datahub_can_access_glue.json
}

data "aws_iam_policy_document" "datahub_can_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.datahub_role.arn]
    }
  }
}

data "aws_iam_policy_document" "datahub_can_access_glue" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabases",
      "glue:GetTables"
    ]
    resources = ["*"]
  }
}