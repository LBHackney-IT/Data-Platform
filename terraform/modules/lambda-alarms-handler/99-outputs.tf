output "lambda_name" {
  description = "Name of the lamda"
  value       = aws_lambda_function.lambda.function_name
}

output "lambda_arn" {
  description = "ARN of the lambda"
  value       = aws_lambda_function.lambda.arn
}
