locals {
  identifier = lower(replace(var.identifier, "_", "-"))
  identifier_prefix = var.identifier_prefix == "" ? "" : "${var.identifier_prefix}-"
}