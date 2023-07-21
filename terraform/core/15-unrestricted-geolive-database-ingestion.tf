module "boundaries_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-boundaries-schema"
  jdbc_connection_url         = "jdbc:postgresql://geolive-db-prod.cjgyygrtgrhl.eu-west-2.rds.amazonaws.com:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access the boundaries schema only"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  identifier_prefix           = local.short_identifier_prefix
  database_secret_name        = "database-credentials/geolive-boundaries"
  schema_name                 = "boundaries"
  job_schedule                = "cron(50 1 ? * MON *)"
}

module "boundaries_geolive_ingestion_job" {
  count                     = local.is_live_environment ? 1 : 0
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_unrestricted
  job_name                   = "${local.short_identifier_prefix}geolive boundaries schema ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  helper_module_key          = aws_s3_object.helpers.key
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  jdbc_connections           = [module.boundaries_geolive_database_ingestion[0].jdbc_connection_name]
  triggered_by_crawler       = module.boundaries_geolive_database_ingestion[0].crawler_name
  workflow_name              = module.boundaries_geolive_database_ingestion[0].workflow_name
  job_parameters = {
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/ingestion-details/"
    "--source_data_database"        = module.boundaries_geolive_database_ingestion[0].ingestion_database_name
  }
  crawler_details = {
    database_name      = module.department_unrestricted.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
    table_prefix = null
  }
}

module "recycling_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-boundaries-in-recycling-schema"
  jdbc_connection_url         = "jdbc:postgresql://geolive-db-prod.cjgyygrtgrhl.eu-west-2.rds.amazonaws.com:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access boundaries layers from recycling schema only"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  identifier_prefix           = local.short_identifier_prefix
  database_secret_name        = "database-credentials/geolive-boundaries"
  schema_name                 = "recycling"
  job_schedule                = "cron(10 2 ? * MON *)"
}

module "recycling_boundaries_geolive_ingestion_job" {
  count                     = local.is_production_environment ? 1 : 0
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_unrestricted
  job_name                   = "${local.short_identifier_prefix}geolive boundaries in recycling schema ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  helper_module_key          = aws_s3_object.helpers.key
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  jdbc_connections           = [module.recycling_geolive_database_ingestion[0].jdbc_connection_name]
  triggered_by_crawler       = module.recycling_geolive_database_ingestion[0].crawler_name
  workflow_name              = module.recycling_geolive_database_ingestion[0].workflow_name
  job_parameters = {
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/ingestion-details/"
    "--source_data_database"        = module.recycling_geolive_database_ingestion[0].ingestion_database_name
  }
  crawler_details = {
    database_name      = module.department_unrestricted.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
    table_prefix = null
  }
}

module "health_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-boundaries-in-health-schema"
  jdbc_connection_url         = "jdbc:postgresql://geolive-db-prod.cjgyygrtgrhl.eu-west-2.rds.amazonaws.com:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access boundaries layers from health schema only"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  identifier_prefix           = local.short_identifier_prefix
  database_secret_name        = "database-credentials/geolive-boundaries"
  schema_name                 = "health"
  job_schedule                = "cron(20 2 ? * MON *)"
}

module "health_boundaries_geolive_ingestion_job" {
  count                     = local.is_production_environment ? 1 : 0
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_unrestricted
  job_name                   = "${local.short_identifier_prefix}geolive boundaries in health schema ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  helper_module_key          = aws_s3_object.helpers.key
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  jdbc_connections           = [module.health_geolive_database_ingestion[0].jdbc_connection_name]
  triggered_by_crawler       = module.health_geolive_database_ingestion[0].crawler_name
  workflow_name              = module.health_geolive_database_ingestion[0].workflow_name
  job_parameters = {
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/ingestion-details/"
    "--source_data_database"        = module.health_geolive_database_ingestion[0].ingestion_database_name
  }
  crawler_details = {
    database_name      = module.department_unrestricted.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
    table_prefix = null
  }
}

module "education_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-boundaries-in-education-schema"
  jdbc_connection_url         = "jdbc:postgresql://geolive-db-prod.cjgyygrtgrhl.eu-west-2.rds.amazonaws.com:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access boundaries layers from education schema only"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  identifier_prefix           = local.short_identifier_prefix
  database_secret_name        = "database-credentials/geolive-boundaries"
  schema_name                 = "education"
  job_schedule                = "cron(30 2 ? * MON *)"
}

module "education_boundaries_geolive_ingestion_job" {
  count                     = local.is_production_environment ? 1 : 0
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_unrestricted
  job_name                   = "${local.short_identifier_prefix}geolive boundaries in education schema ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  helper_module_key          = aws_s3_object.helpers.key
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  jdbc_connections           = [module.education_geolive_database_ingestion[0].jdbc_connection_name]
  triggered_by_crawler       = module.education_geolive_database_ingestion[0].crawler_name
  workflow_name              = module.education_geolive_database_ingestion[0].workflow_name
  job_parameters = {
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/ingestion-details/"
    "--source_data_database"        = module.education_geolive_database_ingestion[0].ingestion_database_name
  }
  crawler_details = {
    database_name      = module.department_unrestricted.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
    table_prefix = null
  }
}

module "housing_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-boundaries-in-housing-schema"
  jdbc_connection_url         = "jdbc:postgresql://geolive-db-prod.cjgyygrtgrhl.eu-west-2.rds.amazonaws.com:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access boundaries layers from housing schema only"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  identifier_prefix           = local.short_identifier_prefix
  database_secret_name        = "database-credentials/geolive-boundaries"
  schema_name                 = "housing"
  job_schedule                = "cron(40 2 ? * MON *)"
}

module "housing_boundaries_geolive_ingestion_job" {
  count                     = local.is_production_environment ? 1 : 0
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_unrestricted
  job_name                   = "${local.short_identifier_prefix}geolive boundaries in housing schema ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  helper_module_key          = aws_s3_object.helpers.key
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  jdbc_connections           = [module.housing_geolive_database_ingestion[0].jdbc_connection_name]
  triggered_by_crawler       = module.housing_geolive_database_ingestion[0].crawler_name
  workflow_name              = module.housing_geolive_database_ingestion[0].workflow_name
  job_parameters = {
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/ingestion-details/"
    "--source_data_database"        = module.housing_geolive_database_ingestion[0].ingestion_database_name
  }
  crawler_details = {
    database_name      = module.department_unrestricted.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/unrestricted/geolive/boundaries/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
    table_prefix = null
  }
}
