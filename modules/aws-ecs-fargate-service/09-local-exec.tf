resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command     = "${path.cwd}/../modules/datahub/deployment-files/deploy.sh ${path.cwd}/../docker/datahub/${var.container_properties.container_name} ${var.ecr_repository_url}"
    interpreter = ["bash", "-c"]
  }
}