resource "aws_glue_crawler" "trusted_zone_housing_repairs_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.trusted_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}trusted-zone-housing-repairs"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.trusted_zone.bucket_id}/housing-repairs/repairs/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

resource "aws_glue_trigger" "housing_repairs_trusted_crawler" {
  tags = module.tags.values

  name = "${local.short_identifier_prefix}housing-repairs-repairs-trusted-crawler-trigger"
  type = "CONDITIONAL"

  predicate {
    logical = "AND"
    conditions {
      job_name = module.communal_lighting[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.door_entry[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.dpa[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.electrical_supplies[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.fire_alarmaov[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.lift_breakdown_el[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.lightning_protection[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.reactive_rewires[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.electric_heating[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.emergency_lighting_servicing[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.tv_aerials[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.housing_repairs_alphatrack[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.housing_repairs_avonline[0].address_matching_job_name
      state    = "SUCCEEDED"
    }

    conditions {
      job_name = module.housing_repairs_axis[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = aws_glue_job.repairs_dlo_levenshtein_address_matching[0].name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.housing_repairs_herts_heritage[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.housing_repairs_purdy[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
    conditions {
      job_name = module.housing_repairs_stannah[0].address_matching_job_name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.trusted_zone_housing_repairs_crawler.name
  }
}
