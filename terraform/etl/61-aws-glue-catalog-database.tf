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

resource "aws_glue_catalog_database" "housing_nec_migration_live_database" {
  name = "housing_nec_migration_live"

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

resource "aws_glue_catalog_database" "housing_nec_migration_partition_databases" {
  # Defined at terraform/etl/60-airflow-variables-and-connnections.tf
  for_each = local.housing_nec_migration_partition_databases

  name = each.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "housing_nec_migration_output_databases" {
  # Defined at terraform/etl/60-airflow-variables-and-connnections.tf
  for_each = local.housing_nec_migration_output_databases

  name = each.value

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

# Keep the Tascomi Glue catalog databases (extracted from the old 24-aws-glue-tascomi-data.tf)
resource "aws_glue_catalog_database" "raw_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-raw-zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "refined_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-refined-zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "trusted_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-trusted-zone"

  lifecycle {
    prevent_destroy = true
  }
}
