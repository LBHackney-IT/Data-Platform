resource "aws_iam_user" "department_user" {
  name = var.department
  tags = var.tags
}

resource "aws_iam_access_key" "department_key" {
  user = aws_iam_user.department_user.name
}

resource "aws_iam_policy" "department_policy" {
  name        = "${var.department}_Policy"
  description = "Policy for ${var.department}"

  policy = var.policy
  tags   = var.tags
}

resource "aws_iam_user_policy_attachment" "attach_department_policy" {
  user       = aws_iam_user.department_user.name
  policy_arn = aws_iam_policy.department_policy.arn
}

resource "aws_secretsmanager_secret" "department_secret" {
  name       = "airflow/connections/${var.department}_aws_default"
  kms_key_id = var.kms_key_id
  tags       = var.tags
}

resource "aws_secretsmanager_secret_version" "department_secret_version" {
  secret_id = aws_secretsmanager_secret.department_secret.id
  secret_string = jsonencode({
    conn_type = "aws",
    login     = aws_iam_access_key.department_key.id,
    password  = aws_iam_access_key.department_key.secret,
    extra     = jsonencode({ region_name = var.region })
  })
}
