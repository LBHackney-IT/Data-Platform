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

resource "aws_glue_catalog_database" "housing_nec_migration_outputs_database" {
  name = "housing_nec_migration_outputs"

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

resource "aws_glue_catalog_database" "housing_service_requests_ieg4" {
  name = "housing_service_requests_ieg4"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "arcus_archive" {
  name = "arcus_archive"

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  department_user_uploads_databases = {
    parking            = "parking_user_uploads_db"
    housing            = "housing_user_uploads_db"
    data_and_insight   = "data_and_insight_user_uploads_db"
    child_fam_services = "child_fam_services_user_uploads_db"
    unrestricted       = "unrestricted_user_uploads_db"
    env_services       = "env_services_user_uploads_db"
    revenues           = "revenues_user_uploads_db"
  }
}

resource "aws_glue_catalog_database" "department_user_uploads" {
  for_each = local.department_user_uploads_databases

  name = each.value

  lifecycle {
    prevent_destroy = true
  }
}
