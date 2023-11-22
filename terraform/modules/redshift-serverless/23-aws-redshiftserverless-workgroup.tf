resource "aws_redshiftserverless_workgroup" "default" {
  tags = var.tags

  namespace_name = aws_redshiftserverless_namespace.namespace.namespace_name
  workgroup_name = var.workgroup_name
  base_capacity  = var.workgroup_base_capacity
  #config_parameter
  enhanced_vpc_routing = false
  publicly_accessible  = false
  security_group_ids   = [aws_security_group.redshift_serverless.id]
  subnet_ids           = var.subnet_ids

  # #setting one will set all existing ones to null, also these can't be updated in a single call. Would have to apply the values one by one
  # config_parameter {
  #     parameter_key = "max_query_execution_time"
  #     parameter_value  = var.maximimum_query_execution_time
  # }

  # #  config_parameter {
  # #       parameter_key   = "auto_mv"
  # #       parameter_value = true
  # #     }
  #  config_parameter {
  #      parameter_key   = "datestyle"
  #      parameter_value = "ISO, MDY"
  #     }
  # #  config_parameter {
  # #      parameter_key   = "enable_case_sensitive_identifier"
  # #      parameter_value = "false"
  # #     }
  #  config_parameter {
  #      parameter_key   = "enable_user_activity_logging"
  #      parameter_value = "true"
  #     }
  #  config_parameter {
  #      parameter_key   = "query_group"
  #      parameter_value = "default"
  #     }
  #  config_parameter {
  #      parameter_key   = "search_path"
  #      parameter_value = "$user, public"
  #     }
  # config_parameter {
  #             parameter_key = "auto_mv"
  #             parameter_value = "true"
  #           }
}

