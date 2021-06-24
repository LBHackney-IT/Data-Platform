resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${local.identifier_prefix}${local.identifier}-landing-zone"
}

resource "aws_glue_catalog_database" "raw_zone_catalog_database" {
  name = "${local.identifier_prefix}${local.identifier}-raw-zone"
}

resource "aws_glue_catalog_database" "refined_zone_catalog_database" {
  name = "${local.identifier_prefix}${local.identifier}-refined-zone"
}

resource "aws_glue_catalog_database" "trusted_zone_catalog_database" {
  name = "${local.identifier_prefix}${local.identifier}-trusted-zone"
}