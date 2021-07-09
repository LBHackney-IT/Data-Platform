resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${var.short_identifier_prefix}${local.department_identifier}-landing-zone"
}

resource "aws_glue_catalog_database" "raw_zone_catalog_database" {
  name = "${var.short_identifier_prefix}${local.department_identifier}-raw-zone"
}

resource "aws_glue_catalog_database" "refined_zone_catalog_database" {
  name = "${var.short_identifier_prefix}${local.department_identifier}-refined-zone"
}

resource "aws_glue_catalog_database" "trusted_zone_catalog_database" {
  name = "${var.short_identifier_prefix}${local.department_identifier}-trusted-zone"
}