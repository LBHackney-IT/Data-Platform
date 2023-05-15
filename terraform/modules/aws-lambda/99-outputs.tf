output "lambda_function_arn" {
  description = "value of the lambda function arn"
  value       = aws_lambda_function.lambda.arn
}

#output "lambda_function_arn_static" {
#  description = "The static arn of the lambda function. Use this to avoid cycle errors between resources (e.g. Step Functions)"
#  
#}

#output "lambda_function_name" {
#  description = "value of the lambda function name"
#  value       = aws_lambda_function.lambda.function_name
#}

