resource "aws_redshiftserverless_usage_limit" "usage_limit" {
  resource_arn  = aws_redshiftserverless_workgroup.default.arn
  usage_type    = "serverless-compute"
  period        = var.serverless_compute_usage_limit_period
  amount        = var.serverless_compute_usage_limit_amount
  breach_action = "log"
}
