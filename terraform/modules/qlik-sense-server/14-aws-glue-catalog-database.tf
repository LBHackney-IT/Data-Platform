resource "aws_glue_catalog_database" "qlik_alb_logs" {
  count = var.is_live_environment ? 1 : 0
  name  = "${var.identifier_prefix}-qlik-alb-logs"

  lifecycle {
    prevent_destroy = true
  }
}
