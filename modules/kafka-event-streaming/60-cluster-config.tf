resource "aws_msk_configuration" "event_streaming" {
  kafka_versions = ["2.8.1"]

  name = "${var.identifier_prefix}event-streaming"

  server_properties = <<PROPERTIES
auto.create.topics.enable=false
delete.topic.enable = false
PROPERTIES
}