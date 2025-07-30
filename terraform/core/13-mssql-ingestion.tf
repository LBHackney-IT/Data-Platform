# As Daro suggested, this will be kept until he returns on 11 August 2025
resource "aws_glue_catalog_database" "landing_zone_academy" {
  name = "${local.short_identifier_prefix}academy-landing-zone"

  lifecycle {
    prevent_destroy = true
  }
}
