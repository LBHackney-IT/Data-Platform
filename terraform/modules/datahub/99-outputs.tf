output "datahub_gms_service_security_group_id" {
    value = module.datahub_gms.security_group_id
}

output "datahub_mae_security_group_id" {
    value = module.datahub_mae_consumer.security_group_id
}

output "datahub_mce_security_group_id" {
    value = module.datahub_mce_consumer.security_group_id
}

output "datahub_actions_security_group_id" {
    value = module.datahub_actions.security_group_id
}
