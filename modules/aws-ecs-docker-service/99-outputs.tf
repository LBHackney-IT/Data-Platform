output "security_group_ids" {
  value = var.container_properties.standalone_onetime_task ? "" : aws_security_group.ecs_tasks[0].id
}