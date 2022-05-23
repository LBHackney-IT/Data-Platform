 # This is a template for prototyping jobs. It loads the latest data from S3 using the Glue catalogue, performs an empty transformation, and writes the result to a target location in S3.
 # Before running your job, go to the Job Details tab and customise:
    # - the role Glue should use to run the job (it should match the department where the data is stored - if not, you will get permissions errors)
    # - the temporary storage path (same as above)
    # - the job parameters (replace the template values coming from the Terraform with real values)

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
from helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.
def get_latest_import(df):
    
   df = df.where(col('import_date') == df.select(max('import_date')).first()[0])
   return df


def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName+'/', '')+'/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f'The job is starting. The source table is {source_catalog_database}.{source_catalog_table}')


    # Load data from glue catalog
    data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space = source_catalog_database,
        table_name = source_catalog_table
        # if the source data IS partitionned by import_date and there is a lot of historic data there that you don't need, consider using a pushdown predicate to only load a few days worth of data and speed up the job   
        # push_down_predicate = create_pushdown_predicate('import_date', 2)
    )

    
    # If the source data is NOT partitioned by import_date, create the necessary import_ columns now and populate them with today's date so the result data gets partitioned as per the DP standards. 
    # Clarification: You normally won't use this if you have used pushdown_predicate and/or get_latest_partition earlier (unless you have dropped or renamed the import_ columns of the source data and want fresh dates to partition the result by processing date)
    # df = add_import_time_columns(df)
    
    # Convert data frame to dynamic frame 
    glueContext = GlueContext(SparkContext.getOrCreate()) 

    data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table,
        push_down_predicate = "import_date=date_format(current_date, 'yyyyMMdd')"
    )
    
    
        
    mapWard = {
                "Hoxton East and Shoreditch": "Hoxton East & Shoreditch"
                }
                
    
    df2 = data_source.toDF()
    # Duplicate ward column to apply mapping
    df2 = df2.withColumn('llpg_ward_map', col('ward').cast('string')) 

    # Apply Mapping
    df2 = df2.replace(to_replace=mapWard, subset=['llpg_ward_map'])

    # get historical and approved addresses
    df_all = df2.filter(col("lpi_logical_status").isin('Approved Preferred','Historic'))

# seperate the lpi key as int
    joinh = df_all.withColumn("lpi_key2", df_all.lpi_key.substr(-9,9))

    joinh = joinh.withColumn("key_int", joinh.lpi_key2.cast('int')) # cast the value as an int

#create the composite key
    joinh = joinh.withColumn('comp_id', concat(joinh.uprn,joinh.key_int))

#get the latest address by lpi key

    latest = joinh.select("uprn","lpi_key")
    latest = latest.withColumnRenamed("uprn","uprn_latest")
    latest = latest.withColumn("lpi_key2", latest.lpi_key.substr(-9,9))

    latest = latest.withColumn("key_int", latest.lpi_key2.cast('int')) # cast the value as an int
    latest2 = latest.groupBy("uprn_latest").max("key_int")
    latest2 = latest2.withColumnRenamed("max(key_int)","key_link")

#create the composite key
    latest3 = latest2.withColumn('comp_id', concat(latest2.uprn_latest,latest2.key_link))

# join the comp ids to get the latest
    joinh2 =  latest3.join(joinh,latest3.comp_id ==  joinh.comp_id,"left")

#drop unwanted columns
    joinh2 = joinh2.drop('key_link','comp_id','max_id','uprn_latest','lpi_key2','key_int','ward')

#create the output
    output = joinh2.withColumnRenamed("llpg_ward_map","ward")
    
    # Convert data frame to dynamic frame 
    #dynamic_frame = DynamicFrame.fromDF(output.repartition(1), glueContext, "target_data_to_write")
    dynamic_frame = DynamicFrame.fromDF(output, glueContext, "target_data_to_write")


# wipe out the target folder in the trusted zone
    clear_target_folder(s3_bucket_target)

# Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target, "partitionKeys": ['import_year', 'import_month', 'import_day', 'import_date']},
        transformation_ctx="target_data_to_write")

    job.commit()

   
