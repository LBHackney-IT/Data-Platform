resource "aws_iam_role" "fargate" {
  tags = var.tags

  name               = "${var.operation_name}fargate"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fargate_ecs_task_execution_attachment" {
  role       = aws_iam_role.fargate.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "fargate_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "task_role" {
  tags = var.tags

  name               = "${var.operation_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role
}

resource "aws_iam_role_policy" "task_role" {
  name   = "${var.operation_name}-task-role-policy"
  role   = aws_iam_role.task_role.id
  policy = var.ecs_task_role_policy_document
}
