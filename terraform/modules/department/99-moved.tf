moved {
  from = aws_iam_role_policy_attachment.airflow_role_datahub_config_access
  to   = aws_iam_role_policy_attachment.airflow_role_datahub_ingestion_access
}

moved {
  from = aws_iam_role_policy_attachment.datahub_config_access_attachment
  to   = aws_iam_role_policy_attachment.datahub_ingestion_access_attachment
}

moved {
  from = aws_iam_policy.datahub_config_access_policy
  to   = aws_iam_policy.datahub_ingestion_access_policy
}

moved {
  from = aws_ssoadmin_customer_managed_policy_attachment.datahub_config_access
  to   = aws_ssoadmin_customer_managed_policy_attachment.datahub_ingestion_access
}
