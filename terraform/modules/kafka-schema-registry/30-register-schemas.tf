resource "null_resource" "register_schemas" {
  for_each = toset(var.topics)
  triggers = {
    shell_hash = filesha256("${path.module}/schemas/${each.value}.json")
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<CMD
      ${path.module}/scripts/update_schemas.sh \
        ${each.value} \
        ${var.bastion_instance_id} \
        ${aws_alb.schema_registry.dns_name} \
        ${var.bastion_private_key_ssm_parameter_name} \
        ${path.module}/schemas/${each.value}.json \
        ${var.is_live_environment}
    CMD
  }

  depends_on = [aws_alb_listener.schema_registry_http]
}
