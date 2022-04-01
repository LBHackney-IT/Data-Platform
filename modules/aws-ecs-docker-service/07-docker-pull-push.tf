resource "null_resource" "docker_pull_push" {

  triggers = {
    shell_hash = sha256("${var.container_properties.image_name}${var.container_properties.image_tag}${var.ecr_repository_url}")
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "${path.module}/docker_pull_push.sh ${var.container_properties.image_name} ${var.container_properties.image_tag} ${var.ecr_repository_url}"
  }
}