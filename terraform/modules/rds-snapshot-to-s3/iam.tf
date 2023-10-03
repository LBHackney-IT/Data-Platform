resource "aws_lambda_permission" "allow_cloudwatch" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  action        = "lambda:InvokeFunction"
  function_name = module.rds-to-s3-copier.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_event_rule[each.key].arn
}

resource "aws_iam_role" "cloudwatch_events_role" {
  name = "cloudwatch-events-invocation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_events_policy" {
  name = "cloudwatch-events-invocation-policy"
  role = aws_iam_role.cloudwatch_events_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = module.rds-to-s3-copier.lambda_function_arn,
      }
    ]
  })
}
