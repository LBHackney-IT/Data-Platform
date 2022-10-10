import sys
from awsglue.transforms import *
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.sql.functions import rank, col, trim, when, max
import pyspark.sql.functions as F
from scripts.helpers.helpers import get_glue_env_var, PARTITION_KEYS

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":

  glueContext = GlueContext(SparkContext.getOrCreate())
  job = Job(glueContext)

  source_catalog_table = get_glue_env_var('source_catalog_table', '')
  source_catalog_table_vaccinations = get_glue_env_var('source_catalog_table_vaccinations', '')
  source_catalog_database = get_glue_env_var('source_catalog_database', '')
  s3_bucket_target = get_glue_env_var('s3_bucket_target', '')

  # Load data from glue catalog
  data_source = glueContext.create_dynamic_frame.from_catalog(
      name_space=source_catalog_database,
      table_name=source_catalog_table,
      transformation_ctx = f"{source_catalog_table}_source"
  )

  # convert to a data frame
  df_locations = data_source.toDF()

  # Load data from glue catalog
  data_source = glueContext.create_dynamic_frame.from_catalog(
      name_space=source_catalog_database,
      table_name=source_catalog_table_vaccinations,
      transformation_ctx = f"{source_catalog_table_vaccinations}_source"
  )

  # convert to a data frame
  df_vaccinations = data_source.toDF()

  # Transform data 

  df_locations = df_locations.withColumnRenamed('location', 'country')

  df_vaccinations.withColumn("date",df_vaccinations.date.cast('date'))

  df_vaccinations = df_vaccinations.withColumnRenamed('location', 'country')


  df_joined = df_locations.join(df_vaccinations, df_locations.country == df_vaccinations.country, 'inner')

  # Convert data frame to dynamic frame 
  dynamic_frame = DynamicFrame.fromDF(df_joined, glueContext, "target_data_to_write")

  # Write the data to S3
  parquet_data = glueContext.write_dynamic_frame.from_options(
      frame=dynamic_frame,
      connection_type="s3",
      format="parquet",
      connection_options={"path": s3_bucket_target, "partitionKeys": PARTITION_KEYS},
      transformation_ctx="target_data_to_write")

  job.commit()
