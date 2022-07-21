import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import *
import pyspark.sql.functions as F
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS_SNAPSHOT

def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName+'/', '')+'/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return


if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    source_catalog_table2 = get_glue_env_var('source_catalog_table2','')
    source_catalog_unrestricted = get_glue_env_var('source_catalog_unrestricted', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    data_source = glueContext.create_dynamic_frame.from_catalog(
            name_space = source_catalog_database,
            table_name = source_catalog_table,
            push_down_predicate = "snapshot_date=date_format(current_date, 'yyyyMMdd')"
     )
    
    data_source2 = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_unrestricted,
            table_name=source_catalog_table2
    )
    
    df = data_source.toDF()
    df = df.withColumn('counter_location', lit(1))

    df2 = data_source2.toDF()
    # Keep Only Relevant Columns
    df2 = df2.select("uprn",
                         "blpu_class",
                         "lpi_key",
                         "lpi_logical_status",
                         "ward",
                         "postcode",
                         "line1",
                         "line2",
                         "line3",
                         "line4",
                         "address_full")
      
    # Rename Relevant Columns
    df2 = df2.withColumnRenamed("lpi_key","llpg_lpi_key") \
                 .withColumnRenamed("blpu_class","llpg_blpu_class") \
                 .withColumnRenamed("uprn","llpg_uprn") \
                 .withColumnRenamed("lpi_logical_status","llpg_logical_status") \
                 .withColumnRenamed("ward","llpg_ward") \
                 .withColumnRenamed("postcode","llpg_postcode") \
                 .withColumnRenamed("line1","llpg_line1") \
                 .withColumnRenamed("line2","llpg_line2") \
                 .withColumnRenamed("line3","llpg_line3") \
                 .withColumnRenamed("line4","llpg_line4") \
                 .withColumnRenamed("address_full","llpg_address") \
    
    join = df.join(df2,df.uprn ==  df2.llpg_uprn,"left")
    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(join, glueContext, "target_data_to_write")

# wipe out the target folder in the trusted zone
    clear_target_folder(s3_bucket_target)

# Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target, "partitionKeys": PARTITION_KEYS_SNAPSHOT},
        transformation_ctx="target_data_to_write")

    job.commit()

