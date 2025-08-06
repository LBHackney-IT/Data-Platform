// =============================================================================
// DEPARTMENT ECS ROLE
// =============================================================================

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

# Department ECS
resource "aws_iam_role" "department_ecs_role" {
  name               = lower("${var.identifier_prefix}-${var.department_identifier}-ecs-task-role")
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "department_ecs_policy" {
  role       = aws_iam_role.department_ecs_role.name
  policy_arn = aws_iam_policy.department_ecs_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_access_attachment_to_ecs_role" {
  role       = aws_iam_role.department_ecs_role.name
  policy_arn = aws_iam_policy.glue_access.arn
}

resource "aws_iam_role_policy" "grant_s3_access_to_ecs_role" {
  role   = aws_iam_role.department_ecs_role.name
  policy = data.aws_iam_policy_document.s3_department_access.json
}

resource "aws_iam_role_policy_attachment" "mtfh_access_attachment" {
  count      = contains(["data-and-insight", "housing"], var.department_identifier) ? 1 : 0
  role       = aws_iam_role.department_ecs_role.name
  policy_arn = aws_iam_policy.mtfh_access_policy[0].arn
}