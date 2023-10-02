data "aws_iam_policy_document" "ecs_execution_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.identifier_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role.json
}
