resource "aws_glue_catalog_database" "hackney_synergy_live" {
  name = "hackney_synergy_live"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "hackney_casemanagement_live" {
  name = "hackney_casemanagement_live"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "child_edu_refined" {
  name = "child_edu_refined"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "housing_nec_migration_database" {
  name = "housing_nec_migration"

  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_glue_catalog_database" "ctax_raw_zone" {
  name = "ctax_raw_zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "nndr_raw_zone" {
  name = "nndr_raw_zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "hben_raw_zone" {
  name = "hben_raw_zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "metastore" {
  name = "metastore"

  lifecycle {
    prevent_destroy = true
  }
}
