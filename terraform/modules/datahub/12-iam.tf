resource "aws_iam_user" "datahub" {
  name = "${var.short_identifier_prefix}datahub-user"
  tags = var.tags
}

resource "aws_iam_access_key" "datahub_access_key" {
  user = aws_iam_user.datahub.name
}

resource "aws_iam_role" "datahub_role" {
  tags               = var.tags
  name               = "${var.short_identifier_prefix}datahub-role"
  assume_role_policy = data.aws_iam_policy_document.datahub_assume_role.json
}

resource "aws_iam_policy_attachment" "datahub_role_policy" {
  name       = "${var.short_identifier_prefix}datahub-role-policy"
  policy_arn = aws_iam_policy.datahub_role_policy.arn
  roles      = [aws_iam_role.datahub_role.name]
}

resource "aws_iam_policy" "datahub_role_policy" {
  policy = data.aws_iam_policy_document.datahub_can_access_glue.json
}

data "aws_iam_policy_document" "datahub_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
    principals {
      identifiers = [aws_iam_user.datahub.arn]
      type        = "AWS"
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

resource "aws_iam_role" "datahub_ecs_autoscale" {
  tags               = var.tags
  name               = "${var.short_identifier_prefix}datahub-ecs-autoscale-role"
  assume_role_policy = data.aws_iam_policy_document.datahub_ecs_autoscale_assume_role.json
}

data "aws_iam_policy_document" "datahub_ecs_autoscale_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["application-autoscaling.amazonaws.com"]
      type        = "Service"
    }
  }
}
