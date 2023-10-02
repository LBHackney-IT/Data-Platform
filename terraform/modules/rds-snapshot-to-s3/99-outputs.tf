output "cloudwatch_event_rule_names" {
  description = "The names of the CloudWatch Event Rules"
  value       = [for rule in aws_cloudwatch_event_rule.rds_event_rule : rule.name]
}