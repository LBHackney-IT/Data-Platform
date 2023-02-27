output "lambda_name" {
  description = "Name of the lamda"
  value       = aws_lambda_function.lambda.function_name
}

output "lambda_arn" {
  description = "ARN of the lambda"
  value       = aws_lambda_function.lambda.arn
}

output "cloudwatch_event_rule_arn" {
  description = "ARN of the CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.lambda.arn
}

output "cloudwatch_event_rule_name" {
  description = "Name of the CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.lambda.name
}
