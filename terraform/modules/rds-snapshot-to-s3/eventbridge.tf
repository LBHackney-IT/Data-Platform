locals {
  rds_instances = [for i in range(length(var.rds_instance_ids)) : {
    id  = var.rds_instance_ids[i]
    arn = var.rds_instance_arns[i]
  }]
}

resource "aws_cloudwatch_event_rule" "rds_snapshot_created_event_rule" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  name        = "rds-event-rule-${each.value.id}-snapshot-created"
  description = "Capture RDS Event 0042 (Snapshot Created) for ${each.value.id}"

  event_pattern = jsonencode({
    source = ["aws.rds"],
    detail = {
      SourceArn = [{
        "prefix" : "arn:aws:rds:eu-west-2:120038763019:snapshot:sql-to-parquet"
      }],
      EventID = ["RDS-EVENT-0042"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "rds_snapshot_created_event_target" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  rule = aws_cloudwatch_event_rule.rds_snapshot_created_event_rule[each.key].name
  arn  = module.trigger_rds_snapshot_export.lambda_function_arn
}

resource "aws_cloudwatch_event_rule" "rds_snapshot_exported_event_rule" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  name        = "rds-event-rule-${each.value.id}-snapshot-exported"
  description = "Capture RDS Event 0161 (Snapshot Exported) for ${each.value.id}"

  event_pattern = jsonencode({
    source = ["aws.rds"],
    detail = {
      SourceArn = [{
        "prefix" : "arn:aws:rds:eu-west-2:120038763019:snapshot:sql-to-parquet"
      }],
      EventID = ["RDS-EVENT-0161"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "rds_export_s3_to_s3_event_target" {
  for_each = { for instance in local.rds_instances : instance.id => instance }

  rule = aws_cloudwatch_event_rule.rds_snapshot_exported_event_rule[each.key].name
  arn  = module.rds_snapshot_s3_to_s3_copier.lambda_function_arn
}
