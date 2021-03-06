resource "null_resource" "docker_pull_push" {

  triggers = {
    shell_hash = sha256("${var.container_properties.image_name}${var.container_properties.image_tag}${aws_ecr_repository.ecr.repository_url}")
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "${path.module}/docker_pull_push.sh ${var.container_properties.image_name} ${var.container_properties.image_tag} ${aws_ecr_repository.ecr.repository_url} ${var.is_live_environment}"
  }

  depends_on = [aws_ecr_repository.ecr]
}