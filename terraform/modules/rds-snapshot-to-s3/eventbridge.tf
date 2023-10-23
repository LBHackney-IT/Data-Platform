locals {
  rds_instances = [for i in range(length(var.rds_instance_ids)) : {
    id  = var.rds_instance_ids[i]
    arn = var.rds_instance_arns[i]
  }]
}

resource "aws_cloudwatch_event_rule" "rds_event_rule" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  name        = "rds-event-rule-${each.value.id}"
  description = "Capture RDS Event 0161 for ${each.value.id}"

  event_pattern = jsonencode({
    source      = ["aws.rds"],
    detail-type = ["RDS DB Instance Event"],
    resources   = [each.value.arn],
    detail = {
      EventCategories = ["snapshot"],
      SourceType      = ["db-instance"],
      Message         = ["RDS-EVENT-0161"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "rds_event_target" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  rule = aws_cloudwatch_event_rule.rds_event_rule[each.key].name
  arn  = module.rds-to-s3-copier.lambda_function_arn
}
