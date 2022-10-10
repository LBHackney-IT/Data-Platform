import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.types import StringType
from pyspark.sql.functions import col, lit, upper
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, add_import_time_columns, PARTITION_KEYS


if __name__ == "__main__":
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    table_list_string = get_glue_env_var('table_list','')
    s3_bucket_source = get_glue_env_var('s3_bucket_source', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    table_list = table_list_string.split(',')
    
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    
    for table in table_list:
        # read from S3 landing zone
        source_url = s3_bucket_source+table+'.csv'
        logger.info(source_url)
        source_ddf = glueContext.create_dynamic_frame_from_options(
            connection_type = "s3",
            connection_options = {"paths": [source_url]}, format = "csv", format_options = { "withHeader": True })

        source_df = source_ddf.toDF()
        source_df = add_import_time_columns(source_df)


        # write back to S3 raw zone
        target_ddf = DynamicFrame.fromDF(
            source_df,
            glueContext,
            "cleanedDataframe"
        )
    
        new_target_bucket = s3_bucket_target+table
        logger.info(new_target_bucket)
        parquet_data = glueContext.write_dynamic_frame.from_options(
            frame=target_ddf,
            connection_type="s3",
            format="parquet",
            connection_options={"path": new_target_bucket, "partitionKeys": PARTITION_KEYS},
            transformation_ctx="noiseworks_"+table)

        job.commit()