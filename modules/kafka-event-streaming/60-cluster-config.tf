#resource "aws_msk_configuration" "mmh_msk_config" {
#  kafka_versions = ["2.1.0"]
#  name           = "${var.identifier_prefix}mmh"
#
#  server_properties = <<PROPERTIES
#auto.create.topics.enable = true
#delete.topic.enable = true
#PROPERTIES
#}