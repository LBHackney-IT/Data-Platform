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


resource "aws_glue_catalog_database" "temp_revenues_academy" {
  name = "temp_revenues_academy"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "temp_benefits_housing_needs_academy" {
  name = "temp_benefits_housing_needs_academy"

  lifecycle {
    prevent_destroy = true
  }
}
