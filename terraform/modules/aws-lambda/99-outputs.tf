output "lambda_function_arn" {
  description = "value of the lambda function arn"
  value       = aws_lambda_function.lambda.arn
}

output "lambda_iam_role" {
  description = "name of the lambda function iam role"
  value       = aws_iam_role.lambda_role.name
}

output "lambda_iam_role_arn" {
  description = "arn of the lambda function iam role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_name" {
  description = "name of the lambda function"
  value       = aws_lambda_function.lambda.function_name
}
