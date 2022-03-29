resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command     = "${coalesce("push.sh", "${path.module}/deployment-files/deploy_containers_to_ecs.sh")} "
    interpreter = ["bash", "-c"]
  }
}