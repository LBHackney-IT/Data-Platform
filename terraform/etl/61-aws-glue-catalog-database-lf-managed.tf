# Lake Formation registration, grants and hybrid opt-ins are managed in
# dap-infrastructure and must be in place before the new ingestion is enabled.
resource "aws_glue_catalog_database" "mosaic_raw" {
  name         = "mosaic_raw"
  description  = "Mosaic SQL Server full-ingestion history and latest datasets."
  location_uri = "s3://${module.raw_zone_data_source.bucket_id}/${local.mosaic_s3_prefix}/"
  tags         = module.tags.values

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_catalog_database" "mosaic_refined" {
  name         = "mosaic_refined"
  description  = "Refined Mosaic datasets."
  location_uri = "s3://${module.refined_zone_data_source.bucket_id}/${local.mosaic_s3_prefix}/"
  tags         = module.tags.values

  lifecycle {
    prevent_destroy = true
  }
}
