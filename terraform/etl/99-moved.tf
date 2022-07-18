moved {
  from = module.repairs_fire_alarm_aov[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.every_day_at_6
  to   = module.repairs_fire_alarm_aov[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.ingestion_schedule
}
moved {
  from = module.env_enforcement_fix_my_street_noise[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.every_day_at_6
  to   = module.env_enforcement_fix_my_street_noise[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.ingestion_schedule
}
moved {
  from = module.env_enforcement_estate_cleaning[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.every_day_at_6
  to   = module.env_enforcement_estate_cleaning[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.ingestion_schedule
}
moved {
  from = module.env_enforcement_cc_tv[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.every_day_at_6
  to   = module.env_enforcement_cc_tv[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.ingestion_schedule
}
moved {
  from = module.data_and_insight_hb_combined[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.every_day_at_6
  to   = module.data_and_insight_hb_combined[0].module.import_file_from_g_drive.aws_cloudwatch_event_rule.ingestion_schedule
}

moved {
  from = module.repairs_fire_alarm_aov[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda_every_day_at_6
  to   = module.repairs_fire_alarm_aov[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda
}
moved {
  from = module.env_enforcement_fix_my_street_noise[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda_every_day_at_6
  to   = module.env_enforcement_fix_my_street_noise[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda
}
moved {
  from = module.env_enforcement_estate_cleaning[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda_every_day_at_6
  to   = module.env_enforcement_estate_cleaning[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda
}
moved {
  from = module.env_enforcement_cc_tv[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda_every_day_at_6
  to   = module.env_enforcement_cc_tv[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda
}
moved {
  from = module.data_and_insight_hb_combined[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda_every_day_at_6
  to   = module.data_and_insight_hb_combined[0].module.import_file_from_g_drive.aws_cloudwatch_event_target.run_lambda
}

