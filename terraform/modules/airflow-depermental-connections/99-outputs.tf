output "user_name" {
  value = aws_iam_user.department_user.name
}

output "access_key_id" {
  value = aws_iam_access_key.department_key.id
}

output "secret_access_key" {
  value = aws_iam_access_key.department_key.secret
}
