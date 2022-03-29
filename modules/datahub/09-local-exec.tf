resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command     = "${coalesce("push.sh", "${path.module}/../../docker/datahub/deploy.sh")} ${var.vpc_id} ${} ${}"
    interpreter = ["bash", "-c"]
  }
}